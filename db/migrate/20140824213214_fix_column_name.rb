class FixColumnName < ActiveRecord::Migration
  def change
  	rename_column :drafts, :type, :draft_type
  end
end
