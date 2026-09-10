# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Players', type: :request do
  describe 'GET /players' do
    context 'ドラフト候補年での絞り込み' do
      it '指定した年の選手のみ表示する' do
        player_2024 = create(:player, name: '2024年候補')
        player_2024.draft_years_text = '2024'
        player_2024.save!

        player_2025 = create(:player, name: '2025年候補')
        player_2025.draft_years_text = '2025'
        player_2025.save!

        get players_path(draft_year: 2024)

        expect(response.body).to include('2024年候補')
        expect(response.body).not_to include('2025年候補')
      end

      it '年を未選択の場合は全選手を表示する' do
        player_2024 = create(:player, name: '2024年候補')
        player_2024.draft_years_text = '2024'
        player_2024.save!

        player_2025 = create(:player, name: '2025年候補')
        player_2025.draft_years_text = '2025'
        player_2025.save!

        get players_path

        expect(response.body).to include('2024年候補')
        expect(response.body).to include('2025年候補')
      end
    end

    context '並び替え' do
      it '候補年が新しい選手が前に来る（作成日時の新旧に関わらない）' do
        recent_year_but_created_first = create(:player, name: '選手A')
        recent_year_but_created_first.draft_years_text = '2025'
        recent_year_but_created_first.save!

        old_year_but_created_later = create(:player, name: '選手B')
        old_year_but_created_later.draft_years_text = '2020'
        old_year_but_created_later.save!

        get players_path

        body = response.body
        expect(body.index('選手A')).to be < body.index('選手B')
      end

      it '未指名のみフィルターと組み合わせてもエラーにならない' do
        team = create(:team)
        draft = create(:draft, year: 2025)

        drafted = create(:player, name: '指名済み選手')
        drafted.draft_years_text = '2025'
        drafted.save!
        create(:pick, player: drafted, draft: draft, team: team, confirmed: true)

        undrafted = create(:player, name: '未指名候補選手')
        undrafted.draft_years_text = '2024'
        undrafted.save!

        get players_path(undrafted_only: '1')

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('未指名候補選手')
        expect(response.body).not_to include('指名済み選手')
      end
    end
  end
end
