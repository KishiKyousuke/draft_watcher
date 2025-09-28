class PlayerPosition < ApplicationRecord
  belongs_to :player
  belongs_to :position

  validates :player_id, presence: true
  validates :position_id, presence: true
end
