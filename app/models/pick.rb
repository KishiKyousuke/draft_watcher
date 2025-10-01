class Pick < ApplicationRecord
  belongs_to :player
  belongs_to :team

  validates :year, presence: true, numericality: { only_integer: true }
  validates :player_id, presence: true
  validates :team_id, presence: true
  validates :draft_round, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :player_id, uniqueness: { scope: :year, message: "は同じ年度に複数回指名できません" }
end
