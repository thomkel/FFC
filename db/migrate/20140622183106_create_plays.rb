class CreatePlays < ActiveRecord::Migration
  def change
    create_table :plays do |t|
      t.integer :player_id
      t.integer :position_id

      t.timestamps
    end
  end
end
