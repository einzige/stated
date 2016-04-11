require 'stated'

class LightSwitch
  include Stated

  state :off, initial: true
  state :on

  event :turn_on do
    transitions from: :off, to: :on
  end

  event :turn_off do
    transitions from: :on, to: :off
  end

  event :smash do
    transitions from: [:off, :on], to: :off
  end
end