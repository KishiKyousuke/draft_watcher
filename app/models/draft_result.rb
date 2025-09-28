class DraftResult < ApplicationRecord
  belongs_to :player
  belongs_to :team, optional: true

  validates :year, presence: true
  validates :player_id, presence: true
end