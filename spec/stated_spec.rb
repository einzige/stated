require 'spec_helper'
require 'pp'

RSpec.describe Stated do

  context 'initial state validation' do
    it {
      expect {
        Class.new do
          include Stated
          state :created, initial: true
          state :running, initial: true
        end
      }.to raise_error /only one/i
    }
  end

  context 'transition definition validation' do
    it {
      expect {
        Class.new do
          include Stated
          state :on
          state :off, initial: true
          event :turn_on do
            transitions
          end
        end
      }.to raise_error /missing from/i
    }

    it {
      expect {
        Class.new do
          include Stated
          state :on
          state :off, initial: true
          event :turn_on do
            transitions from: [:x], to: :y
          end
        end
      }.to raise_error /not defined/i
    }
  end

  context 'transitions exceptions' do
    subject do
      Class.new do
        include Stated
        state :on
        state :off, initial: true

        event :turn_on do
          transitions from: :off, to: :on
        end
      end.new
    end

    before { subject.turn_on! }

    it {
      expect {
        subject.turn_on!
      }.to raise_exception /not possible/
    }
  end

  context 'callbacks' do
    subject do
      Class.new do
        include Stated
        state :on, initial: true
        state :off

        event :turn_on do
          transitions from: [:off], to: :on
        end

        event :turn_off do
          transitions from: [:on], to: :off
        end

        before_state :on do |e|
          puts "callback before on #{e}"
        end

        after_state :on do |e|
          puts "callback after on #{e}"
        end

        before_state :off do |e|
          puts "callback before off #{e}"
        end

        after_event :turn_off do
          puts "lights were switched off"
        end

        on_transition [:on, :off] do
          puts "on -> off has occured"
        end
      end.new(:off)
    end

    it { expect(subject).to be_off }
    it { expect(subject.can_turn_on?).to be true }
    it { expect(subject.can_turn_off?).to be false }

    it {
      expect {
        subject.turn_on!
      }.to change(subject, :state).to(:on)

      expect {
        subject.turn_off!
      }.to change(subject, :state).to(:off)
    }

    it {
      pp subject.class.callbacks
    }
  end
end
