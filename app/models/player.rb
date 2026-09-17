class Player < ApplicationRecord
  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions
  has_many :picks, dependent: :destroy
  has_many :player_draft_years, dependent: :destroy

  validates :name, presence: true
  validates :name_kana, presence: true
  validates :category, presence: true
  validate :draft_years_text_tokens_are_valid

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

  # カンマ区切りの複数ドラフト候補年を返す・設定するための仮想属性
  def draft_years_text
    return @draft_years_text if defined?(@draft_years_text) && !@draft_years_text.nil?

    player_draft_years.order(year: :desc).pluck(:year).join(', ')
  end

  def draft_years_text=(text)
    @draft_years_text = text
    @draft_years_text_invalid_tokens = []

    years = text.to_s.split(',').map(&:strip).reject(&:blank?).map do |token|
      if token.match?(/\A\d+\z/) && token.to_i > 1900
        token.to_i
      else
        @draft_years_text_invalid_tokens << token
        nil
      end
    end.compact.uniq

    existing_by_year = player_draft_years.index_by(&:year)

    self.player_draft_years = years.map { |year| existing_by_year[year] || PlayerDraftYear.new(year: year) }
  end

  def latest_draft_year
    player_draft_years.map(&:year).max
  end

  # 本番ドラフトの確定した指名のみを返す
  def confirmed_picks
    picks.merge(Pick.official).where(confirmed: true)
  end

  # 本番ドラフトで指名されているかを判定
  def drafted_in_official?
    confirmed_picks.exists?
  end

  private

  def draft_years_text_tokens_are_valid
    return if @draft_years_text_invalid_tokens.blank?

    errors.add(:draft_years_text, "に無効な値が含まれています (値: #{@draft_years_text_invalid_tokens.join(', ')})")
  end
end
