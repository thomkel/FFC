class CreateDemands < ActiveRecord::Migration
  def change
    create_table :demands do |t|
      t.league_id :integer
      t.position_id :integer
      t.num_max :integer
      t.num_starters :integer

      t.timestamps
    end
  end
end
