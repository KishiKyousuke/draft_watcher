# ドラフト結果を「球団×指名順位」のマトリクス表として組み立てるサービス
#
# 行は固定ではなく、登録済みの指名結果に応じて動的に伸びる：
#   - 指名1位 / 外れ1位 / 外れ外れ1位 ... : 1位の抽選回数ぶん（抽選が続く限り増える）
#   - 1位確定                             : confirmedな1位指名の再掲（追加不可）
#   - 2位〜N位                            : 支配下指名の最大順位+1まで
#   - 育成1位〜M位                        : 育成指名の最大順位+1まで（0件でも育成1位だけは出す）
class DraftBoard
  Cell = Struct.new(:pick, :add_params, keyword_init: true) do
    def pick?
      pick.present?
    end

    def addable?
      pick.nil? && add_params.present?
    end
  end

  RowView = Struct.new(:label, :cells, keyword_init: true)

  attr_reader :draft

  def initialize(draft)
    @draft = draft
  end

  def teams
    @teams ||= begin
      leagues = @draft.starts_with_central? ? [Team.leagues[:central], Team.leagues[:pacific]] : [Team.leagues[:pacific], Team.leagues[:central]]
      @draft.team_standings
            .eager_load(:team)
            .order(rank: :desc)
            .in_order_of(:league, leagues)
            .map(&:team)
    end
  end

  def rows
    @rows ||= [
      *round1_attempt_rows,
      confirmed_round1_row,
      *regular_round_rows,
      *training_round_rows
    ]
  end

  private

  def picks
    @picks ||= @draft.picks.includes(:player, :team).to_a
  end

  def cells_for_teams
    teams.each_with_object({}) { |team, cells| cells[team.id] = yield(team) }
  end

  # ===== 1位（抽選） =====

  def round1_attempts_by_team
    @round1_attempts_by_team ||= picks
      .select { |p| p.draft_round == 1 && !p.training_player? }
      .group_by(&:team_id)
      .transform_values { |ps| ps.sort_by(&:created_at) }
  end

  def round1_attempt_rows
    # 各球団の「今必要な行数」= 既存の抽選本数 + (最後の抽選が未確定ならもう1本分)
    # これにより、まだ誰も次の抽選を登録していなくても、外れた球団のために次の行が現れる
    needed_rows = teams.map do |team|
      attempts = round1_attempts_by_team[team.id] || []
      attempts.size + (attempts.last && !attempts.last.confirmed? ? 1 : 0)
    end
    max_attempts = [needed_rows.max.to_i, 1].max

    (1..max_attempts).map do |attempt_number|
      cells = cells_for_teams do |team|
        attempts = round1_attempts_by_team[team.id] || []
        pick = attempts[attempt_number - 1]

        if pick
          Cell.new(pick: pick, add_params: nil)
        else
          Cell.new(pick: nil, add_params: round1_add_params(team, attempts, attempt_number))
        end
      end

      RowView.new(label: round1_attempt_label(attempt_number), cells: cells)
    end
  end

  def round1_add_params(team, attempts, attempt_number)
    return round_add_params(team, 1, training_player: false) if attempt_number == 1

    previous_pick = attempts[attempt_number - 2]
    return nil unless previous_pick.present? && !previous_pick.confirmed?

    round_add_params(team, 1, training_player: false)
  end

  def round1_attempt_label(attempt_number)
    return '指名1位' if attempt_number == 1

    "#{'外れ' * (attempt_number - 1)}1位"
  end

  def confirmed_round1_row
    confirmed_by_team = round1_attempts_by_team.transform_values { |ps| ps.find(&:confirmed?) }

    cells = cells_for_teams { |team| Cell.new(pick: confirmed_by_team[team.id], add_params: nil) }

    RowView.new(label: '1位確定', cells: cells)
  end

  # ===== 支配下2位以降 =====

  def regular_picks_by_team_and_round
    @regular_picks_by_team_and_round ||= picks
      .select { |p| !p.training_player? && p.draft_round >= 2 }
      .each_with_object({}) { |p, h| (h[p.draft_round] ||= {})[p.team_id] ||= p }
  end

  def regular_round_rows
    max_round = regular_picks_by_team_and_round.keys.max || 1
    last_round = max_round + 1

    (2..last_round).map do |round|
      cells = cells_for_teams do |team|
        pick = regular_picks_by_team_and_round.dig(round, team.id)

        if pick
          Cell.new(pick: pick, add_params: nil)
        else
          Cell.new(pick: nil, add_params: round_add_params(team, round, training_player: false))
        end
      end

      RowView.new(label: "#{round}位", cells: cells)
    end
  end

  # ===== 育成 =====

  def training_picks_by_team_and_round
    @training_picks_by_team_and_round ||= picks
      .select(&:training_player?)
      .each_with_object({}) { |p, h| (h[p.draft_round] ||= {})[p.team_id] ||= p }
  end

  def training_round_rows
    max_round = training_picks_by_team_and_round.keys.max || 0
    last_round = max_round + 1

    (1..last_round).map do |round|
      cells = cells_for_teams do |team|
        pick = training_picks_by_team_and_round.dig(round, team.id)

        if pick
          Cell.new(pick: pick, add_params: nil)
        else
          Cell.new(pick: nil, add_params: round_add_params(team, round, training_player: true))
        end
      end

      RowView.new(label: "育成#{round}位", cells: cells)
    end
  end

  def round_add_params(team, round, training_player:)
    { draft_id: @draft.id, team_id: team.id, draft_round: round, training_player: training_player }
  end
end
