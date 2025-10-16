class Draft < ApplicationRecord
  has_many :team_standings, dependent: :destroy
  has_many :teams, through: :team_standings

  accepts_nested_attributes_for :team_standings

  validates :year, presence: true, numericality: { only_integer: true }
end
