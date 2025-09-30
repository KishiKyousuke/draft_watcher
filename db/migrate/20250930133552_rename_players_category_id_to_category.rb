class RenamePlayersCategoryIdToCategory < ActiveRecord::Migration[8.0]
  def change
    rename_column :players, :category_id, :category
  end
end
