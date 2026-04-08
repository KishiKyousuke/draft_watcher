class PickCsvExporter
  require 'csv'

  def initialize(picks)
    @picks = picks
  end

  def generate
    CSV.generate(headers: true) do |csv|
      csv << headers
      @picks.each do |pick|
        csv << row_for(pick)
      end
    end
  end

  private

  def headers
    ['ID', 'ドラフト年', '選手名', 'ポジション', '所属', '指名球団', '指名順位', '育成', '確定', '最終指名']
  end

  def row_for(pick)
    [
      pick.id,
      pick.draft.year,
      pick.player.name,
      format_positions(pick.player.positions),
      pick.player.affiliation,
      pick.team.name,
      pick.draft_round,
      boolean_to_string(pick.training_player),
      boolean_to_string(pick.confirmed),
      boolean_to_string(pick.final_pick)
    ]
  end

  def format_positions(positions)
    positions.map(&:short_name).join('/')
  end

  def boolean_to_string(value)
    value ? 'TRUE' : 'FALSE'
  end
end
