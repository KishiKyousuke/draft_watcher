require 'rails_helper'

RSpec.describe DraftBoard do
  let(:draft) { create(:draft) }
  let(:team_a) { create(:team, short_name: 'A') }
  let(:team_b) { create(:team, short_name: 'B') }

  before do
    create(:team_standing, draft: draft, team: team_a, rank: 1)
    create(:team_standing, draft: draft, team: team_b, rank: 2)
  end

  subject(:board) { described_class.new(draft) }

  describe '#teams' do
    it 'ドラフト順（rank降順→リーグ順）で球団を並べる' do
      expect(board.teams).to eq(draft.team_standings.eager_load(:team).order(rank: :desc).map(&:team))
    end
  end

  describe '#rows' do
    it '指名が一件もない場合、指名1位行のみ存在する' do
      labels = board.rows.map(&:label)

      expect(labels).to eq(['指名1位', '1位確定', '2位', '育成1位'])
    end

    it '指名1位行の空セルは常に追加可能' do
      row = board.rows.find { |r| r.label == '指名1位' }
      cell_a = row.cells[team_a.id]

      expect(cell_a.pick?).to eq(false)
      expect(cell_a.addable?).to eq(true)
      expect(cell_a.add_params).to eq(draft_id: draft.id, team_id: team_a.id, draft_round: 1, training_player: false)
    end

    it '指名1位に選手がいれば、そのセルにpickが入り追加不可になる' do
      pick = create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: false, confirmed: false)

      row = board.rows.find { |r| r.label == '指名1位' }
      cell_a = row.cells[team_a.id]

      expect(cell_a.pick).to eq(pick)
      expect(cell_a.addable?).to eq(false)
    end

    it '指名1位が未確定（抽選）の場合のみ外れ1位行が現れ、追加可能になる' do
      create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: false, confirmed: false)

      labels = board.rows.map(&:label)
      expect(labels).to include('外れ1位')

      row = board.rows.find { |r| r.label == '外れ1位' }
      cell_a = row.cells[team_a.id]
      cell_b = row.cells[team_b.id]

      expect(cell_a.addable?).to eq(true)
      expect(cell_a.add_params).to eq(draft_id: draft.id, team_id: team_a.id, draft_round: 1, training_player: false)
      # team_bは指名1位が無いので外れ1位は追加不可
      expect(cell_b.addable?).to eq(false)
    end

    it '指名1位が確定済みの場合、外れ1位行は現れない' do
      create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: false, confirmed: true)

      labels = board.rows.map(&:label)
      expect(labels).not_to include('外れ1位')
    end

    it '抽選が3回続くと外れ外れ1位行まで現れる' do
      travel_to(1.hour.ago) { create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: false, confirmed: false) }
      travel_to(30.minutes.ago) { create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: false, confirmed: false) }
      create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: false, confirmed: true)

      labels = board.rows.map(&:label)
      expect(labels).to include('外れ1位', '外れ外れ1位')

      row = board.rows.find { |r| r.label == '外れ外れ1位' }
      expect(row.cells[team_a.id].pick.confirmed).to eq(true)
    end

    it '1位確定行には、confirmedな1位指名が何本目の抽選であっても再掲される' do
      travel_to(1.hour.ago) { create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: false, confirmed: false) }
      confirmed_pick = create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: false, confirmed: true)

      row = board.rows.find { |r| r.label == '1位確定' }
      cell_a = row.cells[team_a.id]

      expect(cell_a.pick).to eq(confirmed_pick)
      expect(cell_a.addable?).to eq(false)
    end

    it '1位確定がまだ無いチームのセルは空で、追加ボタンも出さない' do
      row = board.rows.find { |r| r.label == '1位確定' }
      cell_a = row.cells[team_a.id]

      expect(cell_a.pick?).to eq(false)
      expect(cell_a.addable?).to eq(false)
      expect(cell_a.add_params).to be_nil
    end

    it '支配下2位以降は登録済みの最大順位の次まで行を出す' do
      create(:pick, draft: draft, team: team_a, draft_round: 2, training_player: false)
      create(:pick, draft: draft, team: team_a, draft_round: 3, training_player: false)

      labels = board.rows.map(&:label)
      expect(labels).to include('2位', '3位', '4位')
      expect(labels).not_to include('5位')
    end

    it '2位以降の空セルは常に追加可能' do
      row = board.rows.find { |r| r.label == '2位' }
      cell_b = row.cells[team_b.id]

      expect(cell_b.addable?).to eq(true)
      expect(cell_b.add_params).to eq(draft_id: draft.id, team_id: team_b.id, draft_round: 2, training_player: false)
    end

    it '育成指名が無い場合でも育成1位行だけは常に出る' do
      labels = board.rows.map(&:label)
      expect(labels.count { |l| l.start_with?('育成') }).to eq(1)
      expect(labels).to include('育成1位')
    end

    it '育成指名は登録済みの最大順位の次まで行を出す' do
      create(:pick, draft: draft, team: team_a, draft_round: 1, training_player: true)
      create(:pick, draft: draft, team: team_a, draft_round: 2, training_player: true)

      labels = board.rows.map(&:label)
      expect(labels).to include('育成1位', '育成2位', '育成3位')
      expect(labels).not_to include('育成4位')
    end

    it '育成行の追加パラメータはtraining_player trueになる' do
      row = board.rows.find { |r| r.label == '育成1位' }
      cell_a = row.cells[team_a.id]

      expect(cell_a.add_params).to eq(draft_id: draft.id, team_id: team_a.id, draft_round: 1, training_player: true)
    end
  end
end
