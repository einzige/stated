# stated

State machine for Ruby.

[![Build Status][travis-ci-badge]][travis-ci]

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stated', github:'otobrglez/stated' # for master

gem 'stated' # once this gets released. ;)
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
    transitions from: :on, to: :off, when: :can_turn_off
  end
  
  before :off do |e|
    puts "Turning lights off. #{e}"
  end
  
  after :off do |e|
    puts "Lights are now off. #{e}"
  end
  
  before_event :turn_off do |e|
    puts "Getting ready to turn off."
  end
  
  on_transition [:off, :on] do
    puts "Lights changed from off to on"
  end
  
  def can_turn_off
    puts "Can turn off?"
    true
  end
end


switch = LightSwitch.new
if switch.can_turn_on?
  switch.turn_on!
end

switch.turn_on! #=> Exception,...

switch.turn_off!

puts switch.on? #=> false
```

This gem depends on [graphviz gem][graphviz]. With method `#save_to` you can save state machine to PNG. Example for [movement_state.rb](spec/movement_state.png).

![Movement state diagram](movement_state.png)

## Development

```bash
gem install bundler & bundle
rspec	# for one-time run
guard # for continues run
```

## Author

- [Oto Brglez](https://github.com/otobrglez)

[travis-ci-badge]:https://travis-ci.org/otobrglez/stated.svg?branch=master
[travis-ci]:https://travis-ci.org/otobrglez/stated
[graphviz]:http://www.rubydoc.info/gems/graphviz 
