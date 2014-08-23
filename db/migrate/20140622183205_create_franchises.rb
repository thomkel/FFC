class CreateFranchises < ActiveRecord::Migration
  def change
    create_table :franchises do |t|
      t.integer :league_id
      t.integer :team_id

      t.timestamps
    end
  end
end
