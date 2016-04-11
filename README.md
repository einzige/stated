# stated

State machine for Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stated'

gem 'stated', github:'otobrglez/stated' # for master
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stated

## Example

```ruby
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
end

switch = LightSwitch.new
if switch.can_turn_on?
  switch.turn_on!
end

puts switch.on? #=> true
```

## Development

```bash
gem install bundler & bundle
rspec	# for one-time run
guard # for continues run
```

## Author

- [Oto Brglez](https://github.com/otobrglez)

