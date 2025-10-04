class PlayerCsvExporter
  require 'csv'

  def initialize(players = Player.includes(:positions).order(:id))
    @players = players
  end

  def generate
    CSV.generate(headers: true) do |csv|
      csv << headers
      @players.each do |player|
        csv << row_for(player)
      end
    end
  end

  private

  def headers
    ['ID', 'カテゴリ', '名前', 'ふりがな', 'ポジション', '投打', '所属', '身長', '体重', '年齢', '寸評']
  end

  def row_for(player)
    [
      player.id,
      translate_category(player.category),
      player.name,
      player.name_kana,
      format_positions(player.positions),
      translate_pitching_batting(player.pitching_batting),
      player.affiliation,
      player.height,
      player.weight,
      player.age,
      player.description
    ]
  end

  def translate_category(category)
    return '' unless category
    I18n.t("activerecord.attributes.player.categories.#{category}")
  end

  def translate_pitching_batting(pitching_batting)
    return '' unless pitching_batting
    I18n.t("activerecord.attributes.player.pitching_battings.#{pitching_batting}")
  end

  def format_positions(positions)
    positions.map(&:short_name).join('/')
  end
end
