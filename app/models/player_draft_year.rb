class PlayerDraftYear < ApplicationRecord
  belongs_to :player

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 1900 }
  validates :year, uniqueness: { scope: :player_id }
end
