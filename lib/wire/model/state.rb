# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

require 'singleton'

# Wire module
module Wire
  # +State+ is a container for a state model
  # :reek:DataClump
  class State
    # [Hash] of all +state+ entries, key=name, value=StateEntry
    attr_accessor :state
    # backref to project
    attr_accessor :project
    # did something change? since last change or load/save
    attr_reader :changed

    include Singleton

    # creates an empty state
    def initialize
      clean
    end

    # cleans the state
    def clean
      @state = {}
      # +changed+ indicates wether state has changed
      @changed = false
    end

    # adds or updates state
    # +type+ i.e. :bridge
    # +name+ i.e. :br0
    # +state+, one of :up, :down, :unknown
    def update(type, name, state)
      key = (make_key(type, name))
      entry = @state[key]
      if entry
        (entry.state != state) && @changed = true
        entry.state = state
      else
        @state.store(key, StateEntry.new(type, name, state))
        @changed = true
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

    # checks if +type+ resource +name+
    # is in state +state_to_check+
    def check(type, name, state_to_check)
      key = (make_key(type, name))
      entry = @state[key]
      return entry.state == state_to_check if entry
      false
    end

    # checks if resource +type+ +name+ is up
    def up?(type, name)
      check(type, name, :up)
    end

    # checks if resource +type+ +name+ is down
    def down?(type, name)
      check(type, name, :down)
    end

    # returns changed flad
    def changed?
      changed
    end

    # calls to_pretty_s on a state entries
    def to_pretty_s
      @state.reduce([]) do |arr, entry|
        arr << entry[1].to_pretty_s
      end.join(',')
    end

    # save current state to statefile (within project target dir)
    def save
      unless @changed
        $log.debug 'Not saving state, nothing changed'
        return
      end
      statefile_filename = state_filename
      $log.debug "Saving state to #{statefile_filename}"
      File.open(statefile_filename, 'w') do |file|
        file.puts state.to_yaml
      end
      @changed = false
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
        clean
      end
      @changed = false
    end

    # construct name of state file
    def state_filename
      File.join(@project.vartmp_dir, '.state.yaml')
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
    def initialize(type, name, state = :unknown)
      self.type = type
      self.name = name
      self.state = state
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
