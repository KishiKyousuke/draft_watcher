class CreateTeamStandings < ActiveRecord::Migration[8.0]
  def change
    create_table :team_standings do |t|
      t.references :draft, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :rank, null: false

      t.timestamps
    end

    add_index :team_standings, [:draft_id, :team_id], unique: true
  end
end
