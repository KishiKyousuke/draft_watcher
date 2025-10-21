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
    last_pick = picks.where(team: team).order(:draft_round).last

    # 1位指名で未確定のものがある場合は1を返す
    if picks.where(team: team, draft_round: 1, training_player: false, confirmed: false).exists?
      return 1
    end

    # 指名がない場合は1
    return 1 if last_pick.nil?

    # 最終指名がある場合は育成指名として扱う
    last_pick.draft_round + 1
  end
end
