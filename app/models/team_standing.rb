class TeamStanding < ApplicationRecord
  belongs_to :draft
  belongs_to :team

  validates :rank, presence: true, numericality: { only_integer: true, in: 1..6 }
  validates :team_id, uniqueness: { scope: :draft_id, message: 'は同じドラフトに複数回登録できません' }
  validates :rank, uniqueness: { scope: :draft_id, message: 'は同じドラフト内で重複できません' }
end
