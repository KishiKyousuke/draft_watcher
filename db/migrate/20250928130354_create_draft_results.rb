class CreateDraftResults < ActiveRecord::Migration[8.0]
  def change
    create_table :draft_results do |t|
      t.references :player, null: false, foreign_key: true
      t.references :team, foreign_key: true, comment: "nullableにして未指名も表現"
      t.integer :year, null: false, comment: "ドラフト年度"
      t.integer :draft_round, comment: "指名順位"
      t.boolean :training_player, default: false, comment: "育成指名フラグ"
      t.timestamps
    end
  end
end
