class RemoveLeagueIdFromTeams < ActiveRecord::Migration
  def change
    remove_column :teams, :team_id, :integer
  end
end
