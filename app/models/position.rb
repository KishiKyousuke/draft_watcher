class Position < ApplicationRecord
  has_many :player_positions, dependent: :destroy
  has_many :players, through: :player_positions

  validates :name, presence: true
  validates :short_name, presence: true
end