class Player < ApplicationRecord
  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions
  has_many :picks, dependent: :destroy

  validates :name, presence: true
  validates :name_kana, presence: true
  validates :category, presence: true

  enum :category, {
    high_school: 0,
    university: 1,
    corporate: 2,
    independent: 3,
    other: 4
  }

  enum :pitching_batting, {
    right_handed_right_batting: 0,
    right_handed_left_batting: 1,
    right_handed_both_batting: 2,
    left_handed_right_batting: 3,
    left_handed_left_batting: 4,
    left_handed_both_batting: 5
  }

  # 本番ドラフトの確定した指名のみを返す
  def confirmed_picks
    picks.joins(:draft)
         .where(drafts: { virtual: false })
         .where(confirmed: true)
  end

  # 本番ドラフトで指名されているかを判定
  def drafted_in_official?
    confirmed_picks.exists?
  end
end
