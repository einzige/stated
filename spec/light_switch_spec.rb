require 'spec_helper'
require 'light_switch'

RSpec.describe LightSwitch do
  let(:described_class) { LightSwitch }

  context "definition" do
    it { expect(described_class).to respond_to :state, :event, :transitions }
    it { expect(described_class.new).to respond_to :state }
  end

  context "#initial_state" do
    subject { described_class.new }

    it "can turn the switch on" do
      if subject.can_turn_on?
        subject.turn_on!
      end

      if subject.can_start_blinking?
        subject.start_blinking!
      end

      if subject.blinking?
        subject.stop_blinking!
      end

      expect(subject).to be_off
      expect(subject.state).to eq :off
    end
  end
end

