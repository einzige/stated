require 'stated/version'

module Stated
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    attr_accessor :states, :transition_table, :initial_state
    attr_accessor :current_state

    def state(state, options={})
      options[:initial] ||= false
      puts 'Adding state %s %s' % [state, options[:initial]]

      self.states = [] if states.nil?
      self.states.push state
      self.initial_state = state if options[:initial]
      self.transition_table = {} if self.transition_table.nil?

      self.current_state = self.initial_state if options[:initial]

      define_method "#{state}?" do
        state == self.class.current_state
      end

      #define_method "can_#{state}?" do
      #  return -2
      #end
    end

    def event(event_name, &block)
      transition_array = yield block

      puts transition_array.inspect
      puts self.states.inspect
    end

    def transitions(definition)
      puts "Adding transitions " + definition.to_s
      if definition[:from].is_a?(Array)
        definition[:from].map { |from| [from, definition[:to]] }
      else
        [definition[:from], definition[:to]]
      end
    end

  end

  module InstanceMethods

    def state
      self.class.current_state
    end
  end
end

