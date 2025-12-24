# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PickCsvExporter, type: :service do
  describe '#generate' do
    context '指名データがある場合' do
      let(:draft) { create(:draft, year: 2024) }
      let(:team) { create(:team, name: '読売ジャイアンツ') }
      let(:player) { create(:player, name: '田中太郎', affiliation: '東京高等学校') }
      let(:position) { create(:position, short_name: '投手') }
      let!(:pick) do
        pick = create(:pick, draft: draft, player: player, team: team, draft_round: 1)
        player.positions << position
        pick
      end

      it 'CSVヘッダーが正しく出力される' do
        exporter = PickCsvExporter.new([pick])
        csv_output = exporter.generate

        lines = csv_output.split("\n")
        header = lines.first

        expect(header).to include('ID')
        expect(header).to include('ドラフト年')
        expect(header).to include('選手名')
        expect(header).to include('ポジション')
        expect(header).to include('所属')
        expect(header).to include('指名球団')
        expect(header).to include('指名順位')
      end

      it '1つのPickオブジェクトからCSV行が生成される' do
        exporter = PickCsvExporter.new([pick])
        csv_output = exporter.generate

        lines = csv_output.split("\n")
        expect(lines.size).to eq(2) # ヘッダー + 1件のデータ
      end

      it 'CSVに日本語が正しく含まれている' do
        exporter = PickCsvExporter.new([pick])
        csv_output = exporter.generate

        expect(csv_output).to include('田中太郎')
        expect(csv_output).to include('東京高等学校')
        expect(csv_output).to include('読売ジャイアンツ')
      end
    end

    context 'Boolean値を含む指名データがある場合' do
      let(:draft) { create(:draft, year: 2024) }
      let(:team) { create(:team, name: '読売ジャイアンツ') }
      let(:player) { create(:player, name: '田中太郎', affiliation: '東京高等学校') }
      let(:position) { create(:position, short_name: '投手') }

      it 'training_player が true の場合、「TRUE」に変換される' do
        pick = create(:pick, draft: draft, player: player, team: team, draft_round: 1, training_player: true)
        player.positions << position

        exporter = PickCsvExporter.new([pick])
        csv_output = exporter.generate

        expect(csv_output).to include('TRUE')
      end

      it 'training_player が false の場合、「FALSE」に変換される' do
        pick = create(:pick, draft: draft, player: player, team: team, draft_round: 1, training_player: false)
        player.positions << position

        exporter = PickCsvExporter.new([pick])
        csv_output = exporter.generate

        expect(csv_output).to include('FALSE')
      end

      it 'confirmed が true の場合、「TRUE」に変換される' do
        pick = create(:pick, draft: draft, player: player, team: team, draft_round: 1, confirmed: true)
        player.positions << position

        exporter = PickCsvExporter.new([pick])
        csv_output = exporter.generate

        expect(csv_output).to include('TRUE')
      end

      it 'final_pick が true の場合、「TRUE」に変換される' do
        pick = create(:pick, draft: draft, player: player, team: team, draft_round: 1, final_pick: true)
        player.positions << position

        exporter = PickCsvExporter.new([pick])
        csv_output = exporter.generate

        expect(csv_output).to include('TRUE')
      end
    end
  end
end
