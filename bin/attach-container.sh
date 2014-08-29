#!/bin/bash

NOOP=
MODE=
[[ $NOOP -eq 1 ]] && MODE='echo NOOP% '

IP=/sbin/ip
OVS_VSCTL=`which ovs-vsctl`

function usage() {
	echo 'ERROR: pw <TARGET-CONTAINER> <container-interface> <switch>'
}

function container_process() {
	T=$1
	local PID=$( docker inspect -f '{{ .State.Pid }}' $T )

	echo $PID
}

function link_netns() {
	local PID=$1
	$MODE sudo ln -s /proc/$PID/ns/net /var/run/netns/$PID
}

function unlink_netns() {
	local PID=$1
	$MODE sudo rm /var/run/netns/$PID
}

function get_mtu() {
	local DEV=$1
	MTU=$(ip link show $DEV | grep mtu | sed -e 's/.*mtu \([0-9]*\) .*/\1/')

	echo $MTU
}

function add_peer_interfaces() {
	local HOST_IF=$1
	local CONTAINER_IF=$2
	local MTU=$3
	$MODE sudo $IP link add name $HOST_IF mtu $MTU type veth peer name $CONTAINER_IF mtu $MTU	
}

function add_device_to_switch() {
	local HOST_IF=$1
	local SWITCH=$2
	$MODE sudo $OVS_VSCTL add-port $SWITCH $HOST_IF
}

function configure_interfaces() {
	local HOST_IF=$1
	local CONTAINER_IF=$2
	local NS=$3
	local DEVICE=$4
	$MODE sudo $IP link set $HOST_IF up
	$MODE sudo $IP link set $CONTAINER_IF netns $NS
	$MODE sudo $IP netns exec $NS ip link set $CONTAINER_IF name $DEVICE
}

function dhcp_container() {
	local NS=$1
	local DEVICE=$2
	$MODE sudo $IP netns exec $NS dhclient $DEVICE
}

TARGET=$1
if [[ -z $TARGET ]]; then
	usage
	exit 1
fi

INTF=$2
if [[ -z $INTF ]]; then
	usage
	exit 2
fi

SWITCH=$3
if [[ -z $SWITCH ]]; then
	usage
	exit 3
fi

$DEBUG echo Connecting $TARGET to $SWITCH on device $INTF ...

TARGET_PID=$(container_process $TARGET)
$DEBUG echo PID of $TARGET is $TARGET_PID

link_netns ${TARGET_PID}

SWITCHDEV_MTU=$(get_mtu $SWITCH)
$DEBUG echo MTU on $SWITCH i $SWITCHDEV_MTU

HOST_IFNAME=v${INTF}h${TARGET_PID}
CONTAINER_IFNAME=v${INTF}c${TARGET_PID}
$DEBUG echo interface pair names are ${HOST_IFNAME}/${CONTAINER_IFNAME}

add_peer_interfaces $HOST_IFNAME $CONTAINER_IFNAME $SWITCHDEV_MTU

add_device_to_switch $HOST_IFNAME $SWITCH

configure_interfaces $HOST_IFNAME $CONTAINER_IFNAME $TARGET_PID $INTF

dhcp_container $TARGET_PID $INTF

unlink_netns $TARGET_PID

