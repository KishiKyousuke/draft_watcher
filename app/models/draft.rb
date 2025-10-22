class Draft < ApplicationRecord
  has_many :team_standings, dependent: :destroy
  has_many :teams, through: :team_standings
  has_many :picks, dependent: :destroy

  accepts_nested_attributes_for :team_standings

  validates :year, presence: true, numericality: { only_integer: true }

  # 特定球団の指名結果を取得
  def picks_by_team(team)
    picks.where(team: team).order(:draft_round, :created_at)
  end

  # 特定球団の次の指名順位を計算
  def next_draft_round_for_team(team)
    team_picks = picks.where(team: team)

    # 指名がない場合は1
    return 1 if team_picks.empty?

    # 確定した指名の最大順位を取得
    confirmed_picks = team_picks.where(confirmed: true).or(team_picks.where(training_player: true))
    max_confirmed_round = confirmed_picks.maximum(:draft_round)

    # 確定した指名がある場合、その次の順位を返す
    return max_confirmed_round + 1 if max_confirmed_round.present?

    # 確定した指名がなく、未確定の1位指名のみの場合は1を返す
    1
  end
end
