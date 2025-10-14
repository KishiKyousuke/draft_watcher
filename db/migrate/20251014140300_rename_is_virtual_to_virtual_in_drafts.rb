class RenameIsVirtualToVirtualInDrafts < ActiveRecord::Migration[8.0]
  def change
    rename_column :drafts, :is_virtual, :virtual
  end
end
