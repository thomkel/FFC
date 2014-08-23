class CreatePicks < ActiveRecord::Migration
  def change
    create_table :picks do |t|
      t.integer :draft_id
      t.integer :pick_num
      t.integer :recruit_id
      t.integer :team_id

      t.timestamps
    end
  end
end
