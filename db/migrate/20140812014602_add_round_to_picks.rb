class AddRoundToPicks < ActiveRecord::Migration
  def change
    add_column :picks, :round, :integer
  end
end
