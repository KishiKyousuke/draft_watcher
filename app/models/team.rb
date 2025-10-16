class Team < ApplicationRecord
  has_many :picks, dependent: :destroy
  has_many :team_standings, dependent: :destroy
  has_many :drafts, through: :team_standings

  validates :name, presence: true
  validates :short_name, presence: true
  validates :league, presence: true

  enum :league, { central: 0, pacific: 1 }
end
