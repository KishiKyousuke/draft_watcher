class Pick < ApplicationRecord
  belongs_to :player
  belongs_to :team
  belongs_to :draft

  validates :player_id, presence: true
  validates :team_id, presence: true
  validates :draft_id, presence: true
  validates :draft_round, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :player_id, uniqueness: {
    scope: :draft_id,
    message: 'は同じドラフトに複数回指名できません',
    if: -> { draft_round != 1 || training_player }
  }

  before_validation :set_confirmed_default, on: :create

  # draftから年度を取得
  def year
    draft&.year
  end

  private

  def set_confirmed_default
    if draft_round == 1 && !training_player
      self.confirmed = false if confirmed.nil?
    end
  end
end
