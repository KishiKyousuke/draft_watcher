# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe PlayerCsvExporter, type: :service do
  describe '#generate' do
    it 'ドラフト候補年をスラッシュ区切りで出力する' do
      player = create(:player, name: '田中太郎')
      player.draft_years_text = '2023, 2024'
      player.save!

      exporter = PlayerCsvExporter.new(Player.where(id: player.id))
      parsed = CSV.parse(exporter.generate, headers: true)

      expect(parsed.first['ドラフト候補年']).to eq('2023/2024')
    end

    it '候補年が未登録の場合は空になる' do
      player = create(:player, name: '鈴木次郎')

      exporter = PlayerCsvExporter.new(Player.where(id: player.id))
      parsed = CSV.parse(exporter.generate, headers: true)

      expect(parsed.first['ドラフト候補年']).to be_blank
    end
  end
end
