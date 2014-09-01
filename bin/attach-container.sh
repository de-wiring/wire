#!/bin/bash
#
# attach-container.sh
# MIT License
# 
# attaches multiple containers to multiple ovs bridges
#

# Display usage and help
function usage() {
        echo 'attach-container.sh <COMMAND> [OPTIONS] -- <device:bridge> [<device:bridge>] <container-id> [<container-id>]'
        echo '  where COMMAND is one of'
        echo '    verify        verify given container/device/bridge options'
        echo '    attach        attach devices to bridges and containers'
        echo '    detach        detach devices from bridges and containers'
	echo '  where OPTIONS are'
 	echo '    -n/--noop 	only print commands, do not change'
 	echo '    -d/--debug 	show debug output'
	echo '  Examples:'
	echo '   attach-containers.sh attach -- eth1:br1 eth2:br2 02978729 12673482'
	echo '   attach-containers.sh verify -- eth1:br1 eth2:br2 02978729 12673482'
	echo '   attach-containers.sh detach -- eth1:br1 eth2:br2 02978729 12673482'
}


# -- FUNCTION ----------------------------------------------------------------
#        Name: split_args
# Description: Splits up args after -- and puts them in DEVICE_ARR/ID_ARR arrays
# ----------------------------------------------------------------------------
function split_args() {
	for ARG in $@; do
       		if [[ "$ARG" =~ .*:.* ]] ; then
                	DEVICE_ARR="$DEVICE_ARR $ARG"
        	else
                	ID_ARR="$ID_ARR $ARG"
        	fi
	done
}

# DEBUG and dummy output
function nodebug() {
	echo $* >/dev/null
}
function debug() {
	[[ "$QUIET" != "1" ]] && echo DEBUG $* 
}
function log_error() {
	echo ERROR $* >&2
}
function log_ok() {
	[[ "$QUIET" != "1" ]] && echo OK $* 
}

NOOP=
MODE=
ACTION=
DEBUG=nodebug

while :
do
    case "$1" in
      verify | attach | detach)
          ACTION=$1
          shift
          ;;
      -h | --help)
          usage
          exit 0
          ;;
      -n | --noop)
          NOOP=1
	  shift
          ;;
      -d | --debug)
          DEBUG=debug
	  shift
          ;;
      --) # End of all options
          shift
	  break
          ;;
      -*)
          echo "Error: Unknown option: $1" >&2
          exit 1
          ;;
      *)  # No more options
          break
          ;;
    esac
done

# Check mandatory input arguments
if [[ -z "$ACTION" ]]; then
        log_error No action given, see usage
        usage
        exit 1
fi

split_args $@

if [[ -z "$DEVICE_ARR" ]]; then
	log_error No device/bridge part specified.
	usage
	exit 2
fi
if [[ -z "$ID_ARR" ]]; then
	log_error No container ids specified.
	usage
	exit 3
fi

[[ "$NOOP" -eq 1 ]] && MODE='echo NOOP% '

# DEBUG
PS4='+|${BASH_SOURCE##*/} ${LINENO}${FUNCNAME[0]:+ ${FUNCNAME[0]}}| '

# locate binaries
# TODO: add defaults
IP=$(which ip)
OVS_VSCTL=$(which ovs-vsctl)
DOCKER=$(which docker)

# -- FUNCTION ----------------------------------------------------------------
#        Name: container_process
# Description: Given ID of container, this returns the Process id
# Parameters
#           1: Docker Container ID
# Returns    : Container Process ID 
# ----------------------------------------------------------------------------
function container_process() {
	T="$1"
	local PID=$(sudo docker inspect -f '{{ .State.Pid }}' "$T")

	echo $PID
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: link_netns
# Description: Puts link in /var/run/netns according to given process id
# Parameters
#           1: Container Process ID
# ----------------------------------------------------------------------------
function link_netns() {
	local PID="$1"
	$MODE sudo ln -s /proc/$PID/ns/net /var/run/netns/$PID
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: unlink_netns
# Description: removes link from /var/run/netns
# Parameters
#           1: Container Process ID
# ----------------------------------------------------------------------------
function unlink_netns() {
	local PID=$1
	$MODE sudo rm /var/run/netns/$PID
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: get_mtu
# Description: Retrieves the MTU for a given device
# Parameters
#           1: Device
# Returns    : MTU
# ----------------------------------------------------------------------------
function get_mtu() {
	local DEV=$1
	local MTU=$(ip link show $DEV | grep mtu | sed -e 's/.*mtu \([0-9]*\) .*/\1/')

	echo $MTU
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: add_peer_interfaces
# Description: creates the host/container peer interfaces
# Parameters
#           1: Host interface name
#           2: Container Interface name
#           3: mtu on bridge
# ----------------------------------------------------------------------------
function add_peer_interfaces() {
	local HOST_IF=$1
	local CONTAINER_IF=$2
	local MTU=$3
	$MODE sudo $IP link add name $HOST_IF mtu $MTU type veth peer name $CONTAINER_IF mtu $MTU	
	return $?
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: add_device_to_switch
# Description: Adds an interface device to given ovs bridge
# Parameters
#           1: interface name
#           2: ovs bridge name
# ----------------------------------------------------------------------------
function add_device_to_switch() {
	local HOST_IF=$1
	local SWITCH=$2
	$MODE sudo $OVS_VSCTL add-port $SWITCH $HOST_IF
	return $?
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: remove_device_from_switch
# Description: Removes an interface device from given ovs bridge
# Parameters
#           1: interface name
#           2: ovs bridge name
# ----------------------------------------------------------------------------
function remove_device_from_switch() {
	local HOST_IF=$1
	local SWITCH=$2
	$MODE sudo $OVS_VSCTL del-port $SWITCH $HOST_IF
	return $?
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: configure_interfaces
# Description: brings container interfaces up, sets namespace and names
# Parameters
#           1: Host interface name
#           2: Container Interface name (peer)
#           3: Namespace (=container pid)
#           4: container device name
# ----------------------------------------------------------------------------
function configure_interfaces() {
	local HOST_IF=$1
	local CONTAINER_IF=$2
	local NS=$3
	local DEVICE=$4
	$MODE sudo $IP link set $HOST_IF up &&  \
	$MODE sudo $IP link set $CONTAINER_IF netns $NS && \
	$MODE sudo $IP netns exec $NS ip link set $CONTAINER_IF name $DEVICE
	return $?
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: delete_interfaces
# Description: deletes the interface pair on host
# Parameters
#           1: Host interface name
#           2: Container Interface name (peer)
#           3: Namespace (=container pid)
#           4: container device name
# Returns    : exit code of ip link delete command
# ----------------------------------------------------------------------------
function delete_interfaces() {
	local HOST_IF=$1
	local CONTAINER_IF=$2
	local NS=$3
	local DEVICE=$4
	$MODE sudo $IP link delete $HOST_IF type veth peer name $CONTAINER_IF
	return $?
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: has_interfaces
# Description: checks if container/host is set up correctly
# Parameters
#           1: Host interface name
#           2: Container Interface name (peer)
#           3: Namespace (=container pid)
#           4: container device name
# Returns    : 0=ok, 1=failed
# ----------------------------------------------------------------------------
function has_interfaces() {
	local HOST_IF=$1
	local CONTAINER_IF=$2
	local NS=$3
	local DEVICE=$4

	# container device
	$MODE sudo $IP netns exec $NS $IP link show $DEVICE >/dev/null 2>&1 
	if [[ $? -ne 0 ]]; then
		return 1
	fi
	# check if we have an ip
	$MODE sudo $IP netns exec $NS $IP addr show $DEVICE 2>&1 | grep 'inet ' >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		return 1
	fi

	# host devices
	$MODE sudo $IP link show $HOST_IF >/dev/null 2>&1 
	if [[ $? -ne 0 ]]; then
		return 1
	fi

	# TODO: CHeck container interface

	return 0
}
	
# -- FUNCTION ----------------------------------------------------------------
#        Name: dhcp_container
# Description: calls dhclient for interface of namespace
# Parameters
#           1: Namespace (=container pid)
#           2: container device name
# Returns    : 0=ok, 1=failed
# ----------------------------------------------------------------------------
function dhcp_container() {
	local NS=$1
	local DEVICE=$2
	$MODE sudo $IP netns exec $NS dhclient $DEVICE
	return $?
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: handle_verify
# Checks if 
# - container ids are valid
# - pids can be queried
# - bridges exist and are up
# - container device names not yet in use
# Returns    : 0=ok, 1=failed
# ----------------------------------------------------------------------------
function handle_verify() {
	local RES=0

	CURRENT_IDS=$(sudo $DOCKER ps -q --no-trunc)
	if [[ -z "$CURRENT_IDS" ]]; then
		log_error No running containers found.
		exit 10
	fi

	for DEVICE_PAIR in $DEVICE_ARR; do
		BRIDGE=$(echo $DEVICE_PAIR | awk -F':' '{ print $2 }' )
		$DEBUG Checking $BRIDGE
		sudo $OVS_VSCTL br-exists $BRIDGE 
		if [[ $? -eq 0 ]]; then
			log_ok $BRIDGE
		else
			log_error Unable to find ovs bridge $BRIDGE
			RES=1
		fi
	done

	# iterate given container ids
	for ID in $ID_ARR; do
		$DEBUG Checking $ID
		if [[ ! $CURRENT_IDS =~ $ID ]]; then
			log_error No container for $ID found, skipping...
			RES=1
		else
			# get pid
			PID=$(container_process $ID)
			if [[ -z $PID ]]; then
				log_error Unable to grab PID for $ID, skipping
				RES=1
			else
				log_ok $ID
				
				# with pid, check given devices
				# on host and in container
	
				$DEBUG - Checking devices in $ID
        			link_netns "${PID}"
        			
				# iterate given devices
				for DEVICE_PAIR in $DEVICE_ARR; do
					INTF=$(echo "$DEVICE_PAIR" | awk -F':' '{ print $1 }' )
					$DEBUG -- Checking $INTF
        				HOST_IFNAME=v${INTF}h${PID}
        				CONTAINER_IFNAME=v${INTF}c${PID}

					has_interfaces $HOST_IFNAME $CONTAINER_IFNAME $PID $INTF 
					if [[ $? -eq 0 ]]; then
						log_ok "$ID"/"$PID" has a "$CONTAINER_IFNAME"
					else 
						log_error "$ID"/"$PID" does not have correct devices
						RES=1
					fi
				done

        			unlink_netns "${PID}"
			fi
		fi
	done

	return $RES
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: handle_attach
# Description: attaches all containers (of $ID_ARR) to all bridges ($DEVICE_ADDR)
#              with its local interface names. Calls dhclient for all interfaces.
# Returns    : 0=ok, 1=failed
# ----------------------------------------------------------------------------
function handle_attach() {
	local RES=0

	# iterate given container ids
	for TARGET in $ID_ARR; do
		$DEBUG Attaching $TARGET
	
		TARGET_PID=$(container_process $TARGET)
        	$DEBUG PID of $TARGET is $TARGET_PID
        
        	link_netns ${TARGET_PID}
        
		# iterate given devices
		for DEVICE_PAIR in $DEVICE_ARR; do
			INTF=$(echo $DEVICE_PAIR | awk -F':' '{ print $1 }' )
			BRIDGE=$(echo $DEVICE_PAIR | awk -F':' '{ print $2 }' )
			$DEBUG Attaching $INTF to $BRIDGE
        	
			BRIDGEDEV_MTU=$(get_mtu $BRIDGE)
			if [[ -z "$BRIDGEDEV_MTU" ]]; then
				log_error querying mtu of $BRIDGE, aborting
				RES=1
				break	
			fi

        		HOST_IFNAME=v${INTF}h${TARGET_PID}
        		CONTAINER_IFNAME=v${INTF}c${TARGET_PID}
        		$DEBUG - interface pair names are ${HOST_IFNAME}/${CONTAINER_IFNAME}

			$DEBUG - creating peer interfaces
        		add_peer_interfaces $HOST_IFNAME $CONTAINER_IFNAME $BRIDGEDEV_MTU
			if [[ $? -ne 0 ]]; then	
				log_error creating peer interfaces. aborting
				RES=1
				continue	
			fi
        
			$DEBUG - adding $HOST_IFNAME to $BRIDGE
        		add_device_to_switch $HOST_IFNAME $BRIDGE
			if [[ $? -ne 0 ]]; then	
				log_error adding device to bridge. aborting
				RES=1
				continue	
			fi
        
			$DEBUG - configuring interfaces
        		configure_interfaces $HOST_IFNAME $CONTAINER_IFNAME $TARGET_PID $INTF
			if [[ $? -ne 0 ]]; then	
				log_error configuring interfaces. aborting
				RES=1
				continue	
			fi
        	
			$DEBUG - dhcp requesting address
        		dhcp_container $TARGET_PID $INTF
			if [[ $? -ne 0 ]]; then	
				log_error running dhcp. aborting
				RES=1
				continue	
			fi
        	done

        	unlink_netns $TARGET_PID
	done

	return $RES
}

# -- FUNCTION ----------------------------------------------------------------
#        Name: handle_detach
# Description: detaches all containers (of $ID_ARR) from all bridges ($DEVICE_ADDR)
#              Removes eth/veth pairs from host
# Returns    : 0=ok, 1=failed
# ----------------------------------------------------------------------------
function handle_detach() {
	local RES=0

	# iterate given container ids
	for TARGET in $ID_ARR; do
		$DEBUG Detaching $TARGET
	
		TARGET_PID=$(container_process $TARGET)
        	$DEBUG PID of $TARGET is $TARGET_PID
        
        	link_netns ${TARGET_PID}
        
		# iterate given devices
		for DEVICE_PAIR in $DEVICE_ARR; do
			INTF=$(echo $DEVICE_PAIR | awk -F':' '{ print $1 }' )
			BRIDGE=$(echo $DEVICE_PAIR | awk -F':' '{ print $2 }' )
        	
        		HOST_IFNAME=v${INTF}h${TARGET_PID}
        		CONTAINER_IFNAME=v${INTF}c${TARGET_PID}
        		$DEBUG - interface pair names are ${HOST_IFNAME}/${CONTAINER_IFNAME}

			$DEBUG - removing $HOST_IFNAME from $BRIDGE
        		remove_device_from_switch $HOST_IFNAME $BRIDGE
			if [[ $? -ne 0 ]]; then	
				log_error removing device from bridge. aborting
				RES=1
				break
			fi

			$DEBUG - delete interfaces 
        		delete_interfaces $HOST_IFNAME $CONTAINER_IFNAME $TARGET_PID $INTF
			if [[ $? -ne 0 ]]; then	
				log_error deleting interfaces
				RES=1
				break
			fi
        	done

        	unlink_netns $TARGET_PID
	done

	return $RES
}

# ========= MAIN ========================================================

if [[ "$ACTION" == "verify" ]]; then 
	handle_verify
	if [[ $? -eq 0 ]]; then	
		log_ok
		exit 0
	else	
		echo FAILED
		exit 100
	fi
fi

if [[ "$ACTION" == "attach" ]]; then 
	handle_attach
	if [[ $? -eq 0 ]]; then	
		log_ok
		exit 0
	else	
		echo FAILED
		exit 100
	fi
fi

if [[ "$ACTION" == "detach" ]]; then 
	handle_detach
	if [[ $? -eq 0 ]]; then	
		log_ok
		exit 0
	else	
		echo FAILED
		exit 100
	fi
fi

