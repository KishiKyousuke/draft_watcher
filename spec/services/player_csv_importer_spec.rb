# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerCsvImporter, type: :service do
  describe '#import' do
    def csv_file_for(content)
      file = double('file')
      allow(file).to receive(:read).and_return(content.dup)
      file
    end

    it 'スラッシュ区切りのドラフト候補年を複数登録する' do
      csv_content = <<~CSV
        カテゴリ,名前,ふりがな,ポジション,投打,所属,身長,体重,年齢,寸評,ドラフト候補年
        高校生,田中太郎,たなかたろう,,,東京高等学校,,,,,2023/2024
      CSV

      importer = PlayerCsvImporter.new(csv_file_for(csv_content))
      result = importer.import

      expect(result).to be true
      expect(Player.last.player_draft_years.pluck(:year)).to contain_exactly(2023, 2024)
    end

    it 'ドラフト候補年が空の場合は登録しない' do
      csv_content = <<~CSV
        カテゴリ,名前,ふりがな,ポジション,投打,所属,身長,体重,年齢,寸評,ドラフト候補年
        高校生,鈴木次郎,すずきじろう,,,大阪高等学校,,,,,
      CSV

      importer = PlayerCsvImporter.new(csv_file_for(csv_content))
      result = importer.import

      expect(result).to be true
      expect(Player.last.player_draft_years).to be_empty
    end

    it '数値に変換できない値が含まれる場合はエラーになる' do
      csv_content = <<~CSV
        カテゴリ,名前,ふりがな,ポジション,投打,所属,身長,体重,年齢,寸評,ドラフト候補年
        高校生,佐藤三郎,さとうさぶろう,,,福岡高等学校,,,,,2023/不正
      CSV

      importer = PlayerCsvImporter.new(csv_file_for(csv_content))
      result = importer.import

      expect(result).to be false
      expect(importer.errors.first).to include('2行目')
      expect(importer.errors.first).to include('ドラフト候補年')
    end
  end
end
