require 'spec_helper'
require 'movement_state'

RSpec.describe MovementState do

  subject { described_class.new(:standing) }

  context 'walking' do
    it { expect(subject).to be_standing }
    it { expect(subject.can_walk?).to be_truthy }
    it {
      expect {
        subject.walk!
      }.to change(subject, :state).to :walking
    }
  end
end