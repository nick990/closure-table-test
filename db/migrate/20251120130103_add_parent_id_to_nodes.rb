class AddParentIdToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :parent_id, :integer
  end
end
