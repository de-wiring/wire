# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

require 'singleton'

# Wire module
module Wire
  # +State+ is a container for a state model
  class State
    # [Hash] of all +state+ entries, key=name, value=StateEntry
    attr_accessor :state
    # backref to project
    attr_accessor :project

    include Singleton

    # creates an empty state
    def initialize
      @state = {}
      # +b_changed+ indicates wether state has changed
      @b_changed = false
    end

    # adds or updates state
    # +type+ i.e. :bridge
    # +name+ i.e. :br0
    # +state+, one of :up, :down, :unknown
    def update(type, name, state)
      key = (make_key(type, name))
      e = @state[key]
      if e
        (e.state != state) && @b_changed = true
        e.state = state
      else
        @state.store(key, StateEntry.new(type, name, state))
        @b_changed = true
      end
    end

    # combines +type+ and +name+ into a key suitable for the hash
    def make_key(type, name)
      "%#{type}%#{name}"
    end

    # checks if we have a state for resource
    # given by +type+ and +name+
    def state?(type, name)
      @state.key?(make_key(type, name))
    end

    def changed?
      b_changed
    end

    # checks if resource +type+ +name+ is up
    def up?(type, name)
      key = (make_key(type, name))
      e = @state[key]
      return e.state == :up if e
      false
    end

    # checks if resource +type+ +name+ is down
    def down?(type, name)
      key = (make_key(type, name))
      e = @state[key]
      return e.state == :down if e
      false
    end

    # calls to_pretty_s on a state entries
    def to_pretty_s
      @state.reduce([]) do |arr, entry|
        arr << entry[1].to_pretty_s
      end.join(',')
    end

    # save current state to statefile (within project target dir)
    def save
      unless @b_changed
        $log.debug 'Not saving state, nothing changed'
        return
      end
      statefile_filename = state_filename
      $log.debug "Saving state to #{statefile_filename}"
      File.open(statefile_filename, 'w') do |f|
        f.puts state.to_yaml
      end
    end

    # load  state from statefile (within project target dir)
    def load
      statefile_filename = state_filename
      if File.exist?(statefile_filename) &&
          File.file?(statefile_filename) &&
          File.readable?(statefile_filename)
        $log.debug "Loading state from #{statefile_filename}"
        @state = YAML.load_file(statefile_filename)
      else
        $log.debug 'No statefile found.'
      end
    end

    # construct name of state file
    def state_filename
      File.join(@project.target_dir, '.state.yaml')
    end
  end

  # A StateEntry combines a resource type,
  # a resource and the state
  class StateEntry
    # +type+ i.e. :bridge
    # +name+ i.e. :br0
    # +state+, one of :up, :down, :unknown
    attr_accessor :type, :name, :state

    # initializes the state entry
    # with given +type+ and +name+ and +state+
    # sets :unknown state if +state+ not given
    def initialize(type, name, state = nil)
      self.type = type
      self.name = name
      self.state = state || :unknown
    end

    # string representation
    def to_s
      "State:[type=#{type}, name=#{name}, state=#{state}]"
    end

    # readble string repr for output
    def to_pretty_s
      "#{type}:#{name} is #{state}"
    end
  end
end
