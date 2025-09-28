class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.string :name, null: false, comment: "ポジション名"
      t.string :short_name, null: false, comment: "略称"
      t.timestamps
    end
  end
end
