class RemovePositionIdFromDemands < ActiveRecord::Migration
  def change
    remove_column :demands, :position_id, :integer
  end
end
