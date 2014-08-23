class AddLeagueToDraft < ActiveRecord::Migration
  def change
    add_column :drafts, :league_id, :integer
  end
end
