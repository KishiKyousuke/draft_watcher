# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pick::Csv::Exports', type: :request do
  let!(:draft) { create(:draft, year: 2024, starts_with_central: true, virtual: false) }
  let!(:team) { create(:team, name: '読売ジャイアンツ') }
  let!(:position) { create(:position, name: '投手', short_name: '投') }
  let!(:player) do
    create(:player, name: '田中太郎', affiliation: '東京高等学校').tap do |p|
      p.positions << position
    end
  end
  let!(:pick) do
    create(:pick, draft: draft, player: player, team: team, draft_round: 1,
                   training_player: false, confirmed: true, final_pick: false)
  end

  describe 'POST /pick/csv/export' do
    context '有効なリクエストの場合' do
      it 'CSVファイルをダウンロードする' do
        post pick_csv_export_path
        expect(response).to have_http_status(200)
        expect(response.content_type).to include('text/csv')
      end

      it '生成されたCSVにヘッダーが含まれる' do
        post pick_csv_export_path
        expect(response.body).to include('ドラフト年')
        expect(response.body).to include('選手名')
      end

      it '生成されたCSVにPickデータが含まれる' do
        post pick_csv_export_path
        expect(response.body).to include('2024')
        expect(response.body).to include('田中太郎')
        expect(response.body).to include('読売ジャイアンツ')
      end

      it 'Content-Dispositionヘッダーが正しく設定される' do
        post pick_csv_export_path
        expect(response.headers['Content-Disposition']).to match(/attachment/)
        expect(response.headers['Content-Disposition']).to match(/picks.*\.csv/)
      end
    end

    context 'Pickが存在しない場合' do
      before { Pick.destroy_all }

      it 'ヘッダーのみのCSVをダウンロードする' do
        post pick_csv_export_path
        expect(response).to have_http_status(200)
        expect(response.content_type).to include('text/csv')
        expect(response.body).to include('ドラフト年')
      end
    end
  end
end
