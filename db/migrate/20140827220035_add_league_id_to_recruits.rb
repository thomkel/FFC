class AddLeagueIdToRecruits < ActiveRecord::Migration
  def change
    add_column :recruits, :league_id, :integer
  end
end
