require 'rails_helper'

RSpec.describe 'Drafts', type: :request do
  describe 'GET /drafts/:id' do
    let(:draft) { create(:draft) }
    let(:team) { create(:team, short_name: 'テスト球団') }

    before do
      create(:team_standing, draft: draft, team: team, rank: 1)
    end

    it '球団の略称を見出しとして表示する' do
      get draft_path(draft)

      expect(response.body).to include('テスト球団')
    end

    it '指名済みのセルには選手名と所属へのリンクを表示する' do
      player = create(:player, name: '山田太郎', affiliation: '○○高校')
      create(:pick, draft: draft, team: team, player: player, draft_round: 1, training_player: false, confirmed: false)

      get draft_path(draft)

      expect(response.body).to include('山田太郎')
      expect(response.body).to include('○○高校')
      expect(response.body).to include(player_path(player))
    end

    it '指名済みのセルには指名編集画面へのリンクも表示する' do
      player = create(:player, name: '山田太郎', affiliation: '○○高校')
      pick = create(:pick, draft: draft, team: team, player: player, draft_round: 1, training_player: false, confirmed: false)

      get draft_path(draft)

      expect(response.body).to include(edit_pick_path(pick))
    end

    it '空セルには、順位と球団が事前入力された指名登録画面へのリンクを表示する' do
      get draft_path(draft)

      expected_path = new_pick_path(draft_id: draft.id, team_id: team.id, draft_round: 1, training_player: false)
      expect(response.body).to include(CGI.escapeHTML(expected_path))
    end
  end
end
