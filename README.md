# "wire up"

[![Gem Version](https://badge.fury.io/rb/dewiring.svg)](http://badge.fury.io/rb/dewiring)
[![inch](http://inch-ci.org/github/de-wiring/wire.png?branch=master)](http://inch-ci.org/github/de-wiring/wire)
[![Build Status](https://travis-ci.org/de-wiring/wire.svg?branch=master)](https://travis-ci.org/de-wiring/wire)

## In a nutshell

**wire** is a model-based approach to virtualized system and network architecture.
It lets you define your architecture in YAML and instantiate it on a host. 
Combining the power of [Docker](https://docker.com), [fig](fig.sh), [serverspec](serverspec.org), 
[Open vSwitch](http://openvswitch.org) and [dnsmasq](http://dnsmasq.org), 
it serves as a simple orchestration tool for both network- and container-related things.

## What

Consider a (very small) architecture consisting of a single network (let's call it "DMZ")
with an ip on the bridge device, dnsmasq on the host and a container attached to it. A model 
might look like this:

```yaml
:zones:
  dmz:
    :desc: Sample demilitarized zone
:networks:
  dmz-net:
    :zone: dmz
    :network: 192.168.10.0/24
    :hostip: 192.168.10.1
    :dhcp:
      :start: 192.168.10.10
      :end: 192.168.10.50
:appgroups:
  dmz_group_1:
    :desc: First application group in DMZ
    :zone: dmz
    :controller:
      :type: fig
      :file: fig/dmz/fig.yml
```
with a additional fig.yml, where a simple    container has been modeled. 

Now, "wire it up":

```bash
$ wire up
model> Loading model in .
1 zones(s), 1 networks(s), 1 appgroups(s)
UP> Bridge dmz-net up.
UP> IP 192.168.10.1/24 on bridge dmz-net up.
UP> dnsmasq/dhcp config on network 'dmz-net' is up.
Creating dmzgroup1_test_1...
UP> appgroup 'dmz_group_1' in zone dmz is up.
UP> appgroup 'dmz_group_1' attached networks dmz-net.
OK
```

This in sum has 
* created an Open vSwitch bridge named "dmz-net",
* assigned the ip 192.168.10.1/24 to it,
* configured dnsmasq to serve ip addresses on the bridge device,
* called "fig up" on fig project/file (which in turn starts a container),
* attached the container to the ovs bridge and
* assigned an ip address to the new container interface via dhcp

Just like "up", additional commands are in place to validate models, to verify
the state on a host, to bring components down in a defined way, and to generate
a clean specification that describes and tests the system.

## Why

So you are all over Docker and want to implement it throughout your stages, from 
development to production. At the same time you are challenged with security concerns, 
migrating your environments from physical to virtual, and scale it over multiple
hosts. IP networks, whether they are physical or virtual, are an essential part of
the equation when building more complex system architectures.

What is de-wiring? It helps you to make your development environments look like production. 
Build your environments with a model approach and have Dev|Prod-Parity in reach. 
Instantiate them, from a single Developer VM to multiple hosts in a production enviroment. 
Specify and document your system, making it testable and audit-proof. 

Integration with tools 
from the Test Driven Infrastructure world offer the ability to automatically test what 
you've specified, including a proper documentation for IT- and Security-Audits.

## How

### Requirements

To fully instantiate models, a host needs

* ruby (=> 1.9.3)
* Open vSwitch
* Docker
* fig
* dnsmasq

Preconfigured Vagrantfiles are available under `test/` subfolder. The easiest way to try
it out:

```
$ cd test/ubuntu
$ vagrant up
$ vagrant ssh
```

The login shell will show an introduction how-to. 

**For a more detailed description, see our Wiki and the 
[Simple Test Case introduction](https://github.com/de-wiring/wire/wiki/SimpleTestCase)**

 
# LICENSE

The MIT License (MIT) Copyright (c) 2014 Andreas Schmidt, Dustin Huptas

* andreas@de-wiring.net
* dustin@de-wiring.net
