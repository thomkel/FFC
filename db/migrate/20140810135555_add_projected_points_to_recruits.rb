class AddProjectedPointsToRecruits < ActiveRecord::Migration
  def change
    add_column :recruits, :projected_points, :integer
  end
end
