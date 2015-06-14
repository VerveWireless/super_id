# SuperId

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'super_id'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install super_id

## Usage

In your model, you can use super id for the primary key

```ruby
# app/models/flock.rb

class Seagull < ActiveRecord::Base
  has_many :seagulls

  use_super_id_for :id
end
```

You can also use super id for foreign keys:

```ruby
# app/models/seagull.rb

class Seagull < ActiveRecord::Base
  belongs_to :flock

  use_super_id_for [:id, :flock_id]
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/encodable_ids/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
