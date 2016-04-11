require 'stated'

class LightSwitch
  include Stated

  state :off, initial: true
  state :on
  state :blinking

  event :turn_on do
    transitions from: :off, to: :on
  end

  event :turn_off do
    transitions from: [:blinking, :on], to: :off
  end

  event :start_blinking do
    transitions from: :on, to: :blinking
  end

  event :stop_blinking do
    transitions from: :blinking, to: :off
  end
end
