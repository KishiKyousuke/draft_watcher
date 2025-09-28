# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ポジションマスタ
positions = [
  { name: "投手", short_name: "投" },
  { name: "捕手", short_name: "捕" },
  { name: "一塁手", short_name: "一" },
  { name: "二塁手", short_name: "二" },
  { name: "三塁手", short_name: "三" },
  { name: "遊撃手", short_name: "遊" },
  { name: "左翼手", short_name: "左" },
  { name: "中堅手", short_name: "中" },
  { name: "右翼手", short_name: "右" }
]

positions.each do |position_data|
  Position.find_or_create_by!(name: position_data[:name]) do |position|
    position.short_name = position_data[:short_name]
  end
end

puts "ポジションマスタを作成しました"

# チームマスタ
teams = [
  # セ・リーグ（2025年順位順）
  { name: "阪神タイガース", short_name: "阪神", league: 0 },
  { name: "横浜DeNAベイスターズ", short_name: "DeNA", league: 0 },
  { name: "読売ジャイアンツ", short_name: "巨人", league: 0 },
  { name: "中日ドラゴンズ", short_name: "中日", league: 0 },
  { name: "広島東洋カープ", short_name: "広島", league: 0 },
  { name: "東京ヤクルトスワローズ", short_name: "ヤクルト", league: 0 },

  # パ・リーグ（2025年順位順）
  { name: "福岡ソフトバンクホークス", short_name: "ソフトバンク", league: 1 },
  { name: "北海道日本ハムファイターズ", short_name: "日本ハム", league: 1 },
  { name: "オリックス・バファローズ", short_name: "オリックス", league: 1 },
  { name: "東北楽天ゴールデンイーグルス", short_name: "楽天", league: 1 },
  { name: "埼玉西武ライオンズ", short_name: "西武", league: 1 },
  { name: "千葉ロッテマリーンズ", short_name: "ロッテ", league: 1 }
]

teams.each do |team_data|
  Team.find_or_create_by!(name: team_data[:name]) do |team|
    team.short_name = team_data[:short_name]
    team.league = team_data[:league]
  end
end

puts "チームマスタを作成しました"
