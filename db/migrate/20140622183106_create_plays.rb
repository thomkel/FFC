class CreatePlays < ActiveRecord::Migration
  def change
    create_table :plays do |t|
      t.player_id :integer
      t.position_id :integer

      t.timestamps
    end
  end
end
