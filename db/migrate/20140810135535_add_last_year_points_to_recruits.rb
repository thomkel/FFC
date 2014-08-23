class AddLastYearPointsToRecruits < ActiveRecord::Migration
  def change
    add_column :recruits, :last_year_points, :integer
  end
end
