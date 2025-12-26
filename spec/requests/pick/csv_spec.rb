# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pick::Csv', type: :request do
  describe 'GET /pick/csv/new' do
    it 'ステータス 200 を返す' do
      get new_pick_csv_path
      expect(response).to have_http_status(200)
    end

    it 'インポートボタンを表示する' do
      get new_pick_csv_path
      expect(response.body).to include('インポート')
    end

    it 'エクスポートボタンを表示する' do
      get new_pick_csv_path
      expect(response.body).to include('エクスポート')
    end
  end
end
