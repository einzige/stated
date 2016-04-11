require 'spec_helper'
require 'light_switch'

RSpec.describe Stated do
  let(:example_class) { LightSwitch }

  context "definition" do
    it { expect(example_class).to respond_to :state, :event, :transitions }
    it { expect(example_class.new).to respond_to :state }
  end

  context "#initial_state" do
    subject { example_class.new }
    it { expect(subject).to be_off }

    it { expect(subject).to respond_to :turn_on! }
    it { expect(subject).to respond_to :turn_off! }
  end
end