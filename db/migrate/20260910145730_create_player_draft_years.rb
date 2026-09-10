class CreatePlayerDraftYears < ActiveRecord::Migration[8.0]
  def change
    create_table :player_draft_years do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :year, null: false

      t.timestamps
    end
    add_index :player_draft_years, [:player_id, :year], unique: true
  end
end
