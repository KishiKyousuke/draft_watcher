require 'rails_helper'

RSpec.describe 'Picks', type: :request do
  describe 'GET /picks/new' do
    let(:draft) { create(:draft) }
    let(:team) { create(:team) }

    it 'draft_roundパラメータがあれば、自動計算せずその順位を事前入力する' do
      create(:pick, draft: draft, team: team, draft_round: 1) # 自動計算なら次は2位になるはず

      get new_pick_path(draft_id: draft.id, team_id: team.id, draft_round: 5)

      expect(response.body).to match(/value="5"[^>]*id="pick_draft_round"/)
    end

    it 'training_playerパラメータがtrueなら、育成指名チェックボックスをチェック済みで表示する' do
      get new_pick_path(draft_id: draft.id, team_id: team.id, draft_round: 1, training_player: true)

      expect(response.body).to match(/checked="checked"[^>]*name="pick\[training_player\]"/)
    end

    it 'draft_roundパラメータが無ければ、従来通り自動計算する' do
      create(:pick, draft: draft, team: team, draft_round: 1)

      get new_pick_path(draft_id: draft.id, team_id: team.id)

      expect(response.body).to match(/value="2"[^>]*id="pick_draft_round"/)
    end
  end
end
