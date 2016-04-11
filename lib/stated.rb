require 'stated/version'
require 'graphviz'

module Stated
  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  module ClassMethods
    attr_accessor :states, :transition_table, :initial_state, :current_state
    attr_accessor :callbacks

    def state(state, options={})
      options[:initial] ||= false
      self.transition_table ||= {}
      self.states ||= []
      self.states.push state

      if options[:initial]
        unless self.initial_state.nil?
          raise OnlyOneInitialState.new('Only one event with initial state is allowed.')
        end

        self.initial_state = state
      end

      self.current_state = self.initial_state if options[:initial]

      define_method "#{state}?" do
        state == self.class.current_state
      end
    end

    def event(event_name, &block)
      (yield block).each do |from, to|
        if valid_transition(from, to)
          self.transition_table[[event_name, from]] = to
        end
      end

      define_method "can_#{event_name}?" do
        self.class.can_execute? event_name
      end

      define_method "#{event_name}!" do
        self.class.execute_event! event_name
      end
    end

    def can_execute?(event_name)
      state, method_or_proc = transition_table[[event_name, current_state]]
      return false if state.nil?

      unless method_or_proc.nil?
        if method_or_proc.is_a?(Proc)
          return method_or_proc.call current_state
        elsif method_or_proc.is_a?(Symbol)
          return instance_method(method_or_proc).bind(self.new).call
        else
          raise StandardError.new('when: can only be Symbol or Proc / lambda.')
        end
      end

      true
    end

    def execute_event!(event_name)
      execute_callbacks :event, :before, event_name

      new_state, method = transition_table[[event_name, current_state]]
      if new_state.nil?
        raise TransitionNotPossible.new('Transition from "%s" is not possible.' % current_state)
      end

      unless method.nil?
        can = if method.is_a?(Proc)
                method.call new_state
              elsif method.is_a?(Symbol)
                instance_method(method).bind(self.new).call
              else
                raise StandardError.new('when can only be Proc or Symbol.')
              end

        unless can
          raise TransitionRejected.new('Transition from "%s" rejected by guard.' % current_state)
        end
      end

      old_state = self.current_state
      self.current_state = new_state

      execute_callbacks :state, :before, new_state, [old_state, new_state]
      execute_callbacks :state, :after, new_state, [old_state, new_state]
      execute_callbacks :event, :after, event_name
      execute_callbacks :transition, :all, [old_state, new_state]

      self.current_state
    end

    def transitions(definition=Hash.new)
      to = [definition[:to], definition[:when]]
      if definition[:from].is_a? Array
        definition[:from].map { |from| [from, to] }
      else
        [[definition[:from], to]]
      end
    end

    def on_transition(events, &block)
      define_callback :transition, :all, events, &block
    end

    def define_callback(callback_type, callback_name, event_name, &block)
      self.callbacks ||= {}
      self.callbacks[[callback_type, callback_name, event_name]] ||= []
      self.callbacks[[callback_type, callback_name, event_name]].push block
    end

    def execute_callbacks(callback_type, callback_name, event_name, value=nil)
      (((self.callbacks || {})[[callback_type, callback_name, event_name]]) || []).each do |callback|
        callback.call value || event_name
      end
    end

    %i{before after}.each do |callback_name|
      %i{event state}.each do |callback_type|
        name = callback_type == :state ? callback_name : "#{callback_name}_#{callback_type}"
        define_method name.to_sym do |event_name, &block|
          define_callback callback_type, callback_name, event_name, &block
        end
      end
    end

    # Errors
    UndefinedState = Class.new(StandardError)
    TransitionNotPossible = Class.new(StandardError)
    OnlyOneInitialState = Class.new(StandardError)
    MissingFromOrTo = Class.new(StandardError)
    TransitionRejected = Class.new(StandardError)

    private

    def valid_transition(from, to_arr)
      to = to_arr.first
      raise MissingFromOrTo.new('Missing from: or to: in your definition.') if from.nil? or to.nil?
      raise UndefinedState.new('State %s is not defined.' % to) unless self.states.include?(to)
      raise UndefinedState.new('State %s is not defined.' % from) unless self.states.include?(from)
      true
    end
  end

  module InstanceMethods
    def initialize(state=nil)
      self.class.current_state = state unless state.nil?
    end

    def state
      self.class.current_state
    end

    def table
      self.class.transition_table
    end

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
end

