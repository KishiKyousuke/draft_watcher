class PlayerCsvImporter
  require 'csv'

  class ImportError < StandardError; end

  attr_reader :errors, :imported_count

  def initialize(csv_file)
    @csv_file = csv_file
    @errors = []
    @imported_count = 0
    @positions_by_short_name = Position.all.index_by(&:short_name)
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
    category = convert_category(row['カテゴリ'], line_number)
    pitching_batting = convert_pitching_batting(row['投打'], line_number)
    position_ids = convert_positions(row['ポジション'], line_number)

    player = Player.new(
      category: category,
      name: row['名前'],
      name_kana: row['ふりがな'],
      pitching_batting: pitching_batting,
      affiliation: row['所属'],
      height: row['身長'],
      weight: row['体重'],
      age: row['年齢'],
      description: row['寸評'],
      position_ids: position_ids
    )

    unless player.save
      error_messages = player.errors.full_messages.join(', ')
      raise ImportError, "#{line_number}行目: #{error_messages}"
    end
  end

  def convert_category(ja_text, line_number)
    return nil if ja_text.blank?

    category = find_enum_key_by_translation('player.categories', ja_text)
    raise ImportError, "#{line_number}行目: カテゴリは一覧にありません (値: #{ja_text})" if category.nil?

    category
  end

  def convert_pitching_batting(ja_text, line_number)
    return nil if ja_text.blank?

    pitching_batting = find_enum_key_by_translation('player.pitching_battings', ja_text)
    raise ImportError, "#{line_number}行目: 投打は一覧にありません (値: #{ja_text})" if pitching_batting.nil?

    pitching_batting
  end

  def find_enum_key_by_translation(i18n_scope, ja_text)
    translations = I18n.t("activerecord.attributes.#{i18n_scope}")
    translations.find { |key, value| value == ja_text }&.first&.to_s
  end

  def convert_positions(position_text, line_number)
    return [] if position_text.blank?

    position_short_names = position_text.split('/')
    position_ids = []

    position_short_names.each do |short_name|
      short_name = short_name.strip
      position = @positions_by_short_name[short_name]
      raise ImportError, "#{line_number}行目: ポジションが見つかりません (値: #{short_name})" if position.nil?

      position_ids << position.id
    end

    position_ids
  end
end
