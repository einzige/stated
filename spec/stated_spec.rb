require 'spec_helper'
require 'pp'

RSpec.describe Stated do
  let(:classWithStated) { Class.new { include Stated } }

  context 'basics' do
    context 'instance' do
      it { expect(classWithStated.new).to respond_to :state }
      it { expect { classWithStated.new(:test) }.to raise_exception(Stated::UndefinedState) }
      it { expect(classWithStated.tap { |klass| klass.state :one }.new(:one).state).to eq :one }
    end

    context 'class' do
      it { expect(classWithStated).to respond_to :states, :transition_table, :initial_state, :current_state, :callbacks }

      context '#state' do
        it { expect(classWithStated).to respond_to :state }
        it 'can have only one initial state' do
          expect {
            classWithStated.tap { |k|
              k.state :a, initial: true
              k.state :b, initial: true
            }
          }.to raise_exception(Stated::OnlyOneInitialState)
        end

        it { expect(classWithStated.tap { |k| k.state :a }.new).to respond_to :a? }
      end

      context '#event' do
        it {
          (expect(classWithStated.tap { |k|
            k.state :hello
            k.event :say_hi
          }.new(:hello))).to respond_to :say_hi!, :can_say_hi?
        }
      end

      context 'definitions' do
        it 'missing' do
          expect { classWithStated.tap { |k|
            k.state :hello
            k.event :say_hi do
              k.transitions
            end
          } }.to raise_exception(Stated::MissingFromOrTo)
        end

        it 'undefined state' do
          expect { classWithStated.tap { |k|
            k.state :hello
            k.event :say_hi do
              k.transitions from: [:x], to: :y
            end
          } }.to raise_exception(Stated::UndefinedState)
        end

        it 'impossible transitions' do
          expect { classWithStated.tap { |k|
            k.state :on
            k.state :off, initial: true
            k.event :turn_on do
              k.transitions from: :off, to: :on
            end
          }.new(:on).turn_on! }.to raise_exception(Stated::TransitionNotPossible)

        end

      end
    end
  end

  context 'callbacks' do
    subject do
      Class.new do
        include Stated
        state :on, initial: true
        state :off
        state :blinking

        event :turn_on do
          transitions from: [:off], to: :on, when: ->(state) { true }
        end

        event :turn_off do
          transitions from: [:on, :blinking], to: :off, when: :turn_off_guard
        end

        event :start_blinking do
          transitions from: [:on], to: :blinking
        end

        event :stop_blinking do
          transitions from: [:blinking], to: :on
        end

        before :on do |e|
          puts "callback before on #{e}"
        end

        after :on do |e|
          puts "callback after on #{e}"
        end

        before :off do |e|
          puts "callback before off #{e}"
        end

        after_event :turn_off do
          puts "lights were switched off"
        end

        on_transition [:on, :off] do |e|
          puts "on_transition #{e}"
        end

        def turn_off_guard
          true
        end
      end.new(:off)
    end

    it { expect(subject).to be_off }
    it { expect(subject.can_turn_on?).to be true }
    it { expect(subject.can_turn_off?).to be !true }
    it { expect(subject.class.callbacks).not_to be_empty }

    it {
      expect(subject.class).to receive(:execute_callbacks).with(any_args).exactly(10)

      expect {
        subject.turn_on!
      }.to change(subject, :state).to(:on)

      expect {
        subject.turn_off!
      }.to change(subject, :state).to(:off)
    }

    it { expect(subject.save_to("stated_spec_ligh.png")).to be_nil }
  end
end
