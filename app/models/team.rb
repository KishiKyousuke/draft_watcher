class Team < ApplicationRecord
  has_many :draft_results, dependent: :destroy

  validates :name, presence: true
  validates :short_name, presence: true
  validates :league, presence: true

  enum league: {
    central: 0,
    pacific: 1
  }
end