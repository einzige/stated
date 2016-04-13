require 'stated/version'
require 'graphviz'

module Stated
  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  module ClassMethods

    # User-defined states of state machine.
    def states
      @states ||= []
    end

    # Table of defined state machine transitions.
    attr_reader :transition_table

    # Initial state of state machine.
    attr_reader :initial_state

    # Current state of state machine.
    attr_accessor :current_state

    # Collection of defined callbacks.
    attr_reader :callbacks

    # Defines new state on this state machine.
    def state(state, options={})
      options[:initial] ||= false

      @transition_table ||= {}
      states.push state

      if options[:initial]
        unless @initial_state.nil?
          raise OnlyOneInitialState.new('Only one event with initial state is allowed.')
        end

        @initial_state = state
      end

      @current_state = @initial_state if options[:initial]

      define_method "#{state}?" do
        state == self.class.current_state
      end
    end

    # Block for defining new events with responding transitions.
    def event(event_name, &block)
      result = yield block if block_given?
      (result || []).each do |from, to|
        if valid_transition(from, to)
          @transition_table[[event_name, from]] = to
        end
      end

      define_method "can_#{event_name}?" do
        self.class.can_execute?(event_name).first
      end

      define_method "#{event_name}!" do
        self.class.execute_event! event_name
      end
    end

    # Can event be executed?
    def can_execute?(event_name)
      state, method_or_proc = @transition_table[[event_name, @current_state]]
      return [false, state] if state.nil?

      unless method_or_proc.nil?
        if method_or_proc.is_a?(Proc)
          return [method_or_proc.call(@current_state), state]
        elsif method_or_proc.is_a?(Symbol)
          return [instance_method(method_or_proc).bind(self.new).call, state]
        else
          raise StandardError.new('when: can only be Symbol or Proc / lambda.')
        end
      end

      [true, state]
    end

    # Executes event, provided as :event_name.
    def execute_event!(event_name)
      execute_callbacks :event, :before, event_name

      can, new_state = can_execute?(event_name)
      raise TransitionNotPossible.new('Transition from "%s" is not possible.' % current_state) unless can

      old_state = @current_state
      @current_state = new_state

      execute_callbacks :state, :before, new_state, [old_state, new_state]
      execute_callbacks :state, :after, new_state, [old_state, new_state]
      execute_callbacks :event, :after, event_name
      execute_callbacks :transition, :all, [old_state, new_state]

      @current_state
    end

    # Defines new transition for event.
    def transitions(definition=Hash.new)
      to = [definition[:to], definition[:when]]
      if definition[:from].is_a? Array
        definition[:from].map { |from| [from, to] }
      else
        [[definition[:from], to]]
      end
    end

    # Defines callback that happens on transition between different states.
    def on_transition(events, &block)
      define_callback :transition, :all, events, &block
    end

    # Defines new callback.
    def define_callback(callback_type, callback_name, event_name, &block)
      @callbacks ||= {}
      @callbacks[[callback_type, callback_name, event_name]] ||= []
      @callbacks[[callback_type, callback_name, event_name]].push block
    end

    # Execute callbacks for type, name and event if they exist.
    def execute_callbacks(callback_type, callback_name, event_name, value=nil)
      (((@callbacks || {})[[callback_type, callback_name, event_name]]) || []).each do |callback|
        callback.call value || event_name
      end
    end

    # Dynamically define before|after_event|state methods for defining callbacks.
    %i{before after}.each do |callback_name|
      %i{event state}.each do |callback_type|
        name = callback_type == :state ? callback_name : "#{callback_name}_#{callback_type}"
        define_method name.to_sym do |event_name, &block|
          define_callback callback_type, callback_name, event_name, &block
        end
      end
    end

    # Validate transition between states
    def valid_transition(from, to_arr)
      to = to_arr.first
      raise MissingFromOrTo.new('Missing from: or to: in your definition.') if from.nil? or to.nil?
      raise UndefinedState.new('State %s is not defined.' % to) unless @states.include?(to)
      raise UndefinedState.new('State %s is not defined.' % from) unless @states.include?(from)
      true
    end


    def select_states
      @transition_table.select { |(_, state), (_, _)| state == current_state }
    end

    def possible_states
      select_states.map { |(_, _), (to, _)| to }
    end

    def possible_events
      select_states.map { |(event, _), (_, _)| event }
    end
  end

  module InstanceMethods

    # Initializes new state machine with some state
    def initialize(state=nil)
      if !state.nil? and !self.class.states.include?(state)
        raise UndefinedState.new('State %s is not defined.' % state)
      end

      self.class.current_state = state unless state.nil?
    end

    def state
      self.class.current_state
    end

    def possible_states
      self.class.possible_states
    end

    def possible_events
      self.class.possible_events
    end

    def table
      self.class.transition_table
    end

    # Saves state machine to file. Types PNG or PDF.
    def save_to(path)
      g = Graphviz::Graph.new
      nodes = Hash[self.class.states.map do |s|
        [s, g.add_node(s, node_attributes(s))]
      end]

      table.each do |(label, from), (to, guard)|
        Graphviz::Edge.new g, nodes[from], nodes[to], label: label
      end

      Graphviz::output(g, path: path)
    end

    private

    def node_attributes(state)
      if state == self.class.initial_state
        {fillcolor: 'green', style: 'filled'}
      else
        {fillcolor: 'lightgrey', style: 'filled'}
      end
    end
  end

  # Exceptions
  UndefinedState = Class.new(StandardError)
  TransitionNotPossible = Class.new(StandardError)
  OnlyOneInitialState = Class.new(StandardError)
  MissingFromOrTo = Class.new(StandardError)
  TransitionRejected = Class.new(StandardError)
end

