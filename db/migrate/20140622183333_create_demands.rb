class CreateDemands < ActiveRecord::Migration
  def change
    create_table :demands do |t|
      t.integer :league_id
      t.integer :position_id
      t.integer :max_per_position
      t.integer :num_starters

      t.timestamps
    end
  end
end
