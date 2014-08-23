class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer :draft_id
      t.integer :team_id
      t.integer :order_position

      t.timestamps
    end
  end
end
