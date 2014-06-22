class CreateRecruits < ActiveRecord::Migration
  def change
    create_table :recruits do |t|
      t.team_id :integer
      t.player_id :integer

      t.timestamps
    end
  end
end
