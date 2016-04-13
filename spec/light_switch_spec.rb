require 'spec_helper'
require 'light_switch'

RSpec.describe LightSwitch do
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

