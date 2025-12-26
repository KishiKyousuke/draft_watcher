# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pick::Imports', type: :request do
  def csv_file_for(content)
    file = Tempfile.new('picks.csv')
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'text/csv')
  end

  describe 'GET /pick/import/new' do
    it 'ステータス 200 を返す' do
      get '/pick/import/new'
      expect(response).to have_http_status(200)
    end

    it 'new テンプレートをレンダリングする' do
      get '/pick/import/new'
      expect(response.body).to include('インポート')
    end
  end

  describe 'POST /pick/import' do
    let!(:team) { create(:team, name: '読売ジャイアンツ') }
    let!(:player) { create(:player, name: '田中太郎', affiliation: '東京高等学校') }

    context '有効な CSV ファイルの場合' do
      it '指名結果をインポートして picks_path にリダイレクトする' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
        CSV

        file = csv_file_for(csv_content)

        post '/pick/import', params: { import: { csv_file: file } }

        expect(response).to redirect_to(picks_path)
        expect(flash[:notice]).to include('インポートしました')
      end

      it 'フラッシュにインポート件数を表示する' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
        CSV

        file = csv_file_for(csv_content)

        post '/pick/import', params: { import: { csv_file: file } }

        expect(flash[:notice]).to include('1件')
      end
    end

    context 'CSV ファイルがない場合' do
      it 'new_pick_import_path にリダイレクトする' do
        post '/pick/import', params: { import: {} }

        expect(response).to redirect_to(new_pick_import_path)
        expect(flash[:alert]).to be_present
      end
    end

    context '不正な CSV データの場合' do
      it 'new_pick_import_path にリダイレクトしてエラーを表示する' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,存在しない選手,不明高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
        CSV

        file = csv_file_for(csv_content)

        post '/pick/import', params: { import: { csv_file: file } }

        expect(response).to redirect_to(new_pick_import_path)
        expect(flash[:alert]).to include('選手が見つかりません')
      end
    end
  end
end
