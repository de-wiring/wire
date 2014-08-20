# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

require 'ipaddr'

# reopen class to add needed methods
# for IP/subnetwork stuff
class IPAddr
  # TODO: check if needed
  # attr_reader :netmask_address

  # compute broadcast address
  def broadcast_address
    _to_string(@addr | (2**32 - 1) - (@mask_addr))
  end

  # checks if self is within network range
  # of given +network+ (IPAddr object)
  # i.e. 10.10.2.0/24 is part of 10.10.0.0/16
  # params:
  # +network+ i.e. 10.10.0.0/16, if self == 10.10.2.0/24
  # returns
  # [bool]
  def in_range_of?(network)
    return false unless network.include?(self)
    return false unless
        network.include?(IPAddr.new(broadcast_address))
    true
  end

  # return netmask as a string
  def netmask
    _to_string(@mask_addr)
  end
end
