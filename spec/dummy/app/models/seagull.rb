class Seagull < ActiveRecord::Base
  belongs_to :flock

  use_super_id_for [:id, :flock_id]
end
