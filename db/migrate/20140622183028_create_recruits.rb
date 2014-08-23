class CreateRecruits < ActiveRecord::Migration
  def change
    create_table :recruits do |t|
      t.integer :team_id
      t.integer :player_id

      t.timestamps
    end
  end
end
