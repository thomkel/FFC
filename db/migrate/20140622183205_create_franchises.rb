class CreateFranchises < ActiveRecord::Migration
  def change
    create_table :franchises do |t|
      t.league_id :integer
      t.team_id :integer

      t.timestamps
    end
  end
end
