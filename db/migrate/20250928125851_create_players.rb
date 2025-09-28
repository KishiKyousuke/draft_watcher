class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.integer :category_id, null: false, comment: "カテゴリ（0:高校生, 1:大学生, 2:社会人, 3:独立, 4:その他）"
      t.string :name, null: false, comment: "名前"
      t.string :name_kana, null: false, comment: "ふりがな"
      t.integer :pitching_batting, comment: "投打"
      t.string :affiliation, comment: "所属"
      t.integer :height, comment: "身長"
      t.integer :weight, comment: "体重"
      t.integer :age, comment: "年齢"
      t.text :description, comment: "寸評"
      t.timestamps
    end
  end
end
