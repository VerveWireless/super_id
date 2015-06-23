class Flock < ActiveRecord::Base
  has_many :seagulls

  use_super_id_for :id
end
