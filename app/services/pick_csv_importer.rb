class PickCsvImporter
  require 'csv'

  class ImportError < StandardError; end

  attr_reader :errors, :imported_count

  def initialize(csv_file)
    @csv_file = csv_file
    @errors = []
    @imported_count = 0
  end

  def import
    csv_text = @csv_file.read.force_encoding('UTF-8')
    csv = CSV.parse(csv_text, headers: true)

    ActiveRecord::Base.transaction do
      csv.each_with_index do |row, index|
        line_number = index + 2 # ヘッダー行が1行目なので+2
        import_row(row, line_number)
      end
      @imported_count = csv.size
    end

    true
  rescue CSV::MalformedCSVError => e
    @errors << "CSVファイルの形式が正しくありません: #{e.message}"
    false
  rescue ImportError => e
    @errors << e.message
    false
  end

  private

  def import_row(row, line_number)
    year = row['ドラフト年'].to_i
    player_name = row['選手名']
    affiliation = row['所属']
    team_name = row['指名球団']
    draft_round = row['指名順位'].to_i
    training_player = convert_boolean(row['育成'], line_number)
    confirmed = convert_boolean(row['確定'], line_number)
    final_pick = convert_boolean(row['最終指名'], line_number)

    # ドラフトを検索または作成
    draft = Draft.find_or_create_by(year: year) do |d|
      d.starts_with_central = true
      d.virtual = false
    end

    # 選手を検索
    player = Player.find_by(name: player_name, affiliation: affiliation)
    raise ImportError, "#{line_number}行目: 選手が見つかりません (名前: #{player_name}, 所属: #{affiliation})" if player.nil?

    # 球団を検索
    team = Team.find_by(name: team_name)
    raise ImportError, "#{line_number}行目: 球団が見つかりません (名前: #{team_name})" if team.nil?

    # Pick を作成
    pick = Pick.new(
      draft: draft,
      player: player,
      team: team,
      draft_round: draft_round,
      training_player: training_player,
      confirmed: confirmed,
      final_pick: final_pick
    )

    unless pick.save
      error_messages = pick.errors.full_messages.join(', ')
      raise ImportError, "#{line_number}行目: #{error_messages}"
    end
  end

  def convert_boolean(value, line_number)
    return false if value.blank?

    case value.upcase
    when 'TRUE'
      true
    when 'FALSE'
      false
    else
      raise ImportError, "#{line_number}行目: Boolean値が正しくありません (値: #{value})"
    end
  end
end
