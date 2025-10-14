class CreateDrafts < ActiveRecord::Migration[8.0]
  def change
    create_table :drafts do |t|
      t.integer :year, null: false
      t.boolean :starts_with_central, default: true
      t.boolean :is_virtual, default: false

      t.timestamps
    end
  end
end
