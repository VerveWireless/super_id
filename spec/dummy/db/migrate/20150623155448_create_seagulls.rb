class CreateSeagulls < ActiveRecord::Migration
  def change
    create_table :seagulls do |t|
      t.references :flock, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
