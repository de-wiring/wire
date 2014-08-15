# encoding: utf-8

require 'ipaddr'

# reopen class to add needed methods
# for IP/subnetwork stuff
class IPAddr
  attr_reader :netmask_address

  # compute broadcast address
  def broadcast_address
    _to_string(@addr | (2**32 - 1) - (@mask_addr))
  end

  # checks if self is within network range
  # of given network (IPAddr object)
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
