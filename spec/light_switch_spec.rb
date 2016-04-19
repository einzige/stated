require 'spec_helper'
require 'light_switch'

RSpec.describe LightSwitch do
  context 'two instances' do
    let(:instance_1) { LightSwitch.new }
    let(:instance_2) { LightSwitch.new }

    it 'does not allow instance_2 to start blinking' do
      expect {
        instance_2.start_blinking!
      }.to raise_exception Stated::TransitionNotPossible
    end

    context 'instance_1 turned on' do
      before do
        instance_1.turn_on!
      end

      it 'still does not allow instance_2 to start blinging' do
        expect {
          instance_2.start_blinking!
        }.to raise_exception Stated::TransitionNotPossible
      end
    end
  end

  it 'acts as regular switch with blinking' do
    expect(subject).to be_off
    expect(subject.possible_events).to match_array %i{turn_on}

    expect {
      subject.turn_off!
    }.to raise_exception Stated::TransitionNotPossible

    expect(subject.can_turn_on?).to be true

    if subject.can_turn_on?
      subject.turn_on!
    end

    expect(subject).to be_on
    expect(subject.can_start_blinking?).to be true
    expect(subject.possible_states).to match_array [:off, :blinking]

    if subject.can_start_blinking?
      subject.start_blinking!
    end

    expect(subject).to be_blinking

    if subject.blinking?
      subject.stop_blinking!
    end

    expect(subject).to be_off
    expect(subject.state).to eq :off

    expect(subject.possible_states).to match_array %i{on}

    subject.save_to('light_switch.png')
  end
end

