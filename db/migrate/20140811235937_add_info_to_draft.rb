class AddInfoToDraft < ActiveRecord::Migration
  def change
    add_column :drafts, :type, :string
  end
end
