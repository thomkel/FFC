class RemoveRecruitIdFromPicks < ActiveRecord::Migration
  def change
    remove_column :picks, :recruit_id, :integer
  end
end
