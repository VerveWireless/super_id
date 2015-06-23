# SuperId

Disguise your model ID's when displayed in the UI or API

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

class Flock < ActiveRecord::Base
  has_many :seagulls

  use_super_id_for :id
end
```

You can use super id for foreign keys too:

```ruby
# app/models/seagull.rb

class Seagull < ActiveRecord::Base
  belongs_to :flock

  use_super_id_for [:id, :flock_id]
end
```

## Options

### :as

SuperId potentially supports multiple encoding algorithms, but currently is limited to short uid.

Optional
Default: `:short_id`

```ruby
# app/models/flock.rb
class Flock < ActiveRecord::Base
  has_many :seagulls

  use_super_id_for :id, as: :short_uid
end
```

## Encoding Algorithms

Each encoding algorithm may have options of its own, which can be added to the `use_super_id_for` arguments.

### Short UID

Options and defaults

* `salt`: ''
* `min_hash_length`: 0
* `alphabet`: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'

For example, you can use a different salt for each model, and it will encode equal id's differently:

```ruby
# app/models/flock.rb
class Flock < ActiveRecord::Base
  has_many :seagulls

  use_super_id_for :id, as: :short_uid, salt: 'foo'
end

# app/models/seagull.rb
class Seagull < ActiveRecord::Base
  belongs_to :flock

  use_super_id_for [:id, :flock_id], as: :short_uid, salt: 'bar'
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/encodable_ids/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
