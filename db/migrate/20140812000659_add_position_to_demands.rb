class AddPositionToDemands < ActiveRecord::Migration
  def change
    add_column :demands, :position, :string
  end
end
