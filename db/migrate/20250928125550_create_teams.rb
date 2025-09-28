class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false, comment: "球団名"
      t.string :short_name, null: false, comment: "略称"
      t.string :league, null: false, comment: "セ・リーグ/パ・リーグ"
      t.timestamps
    end
  end
end
