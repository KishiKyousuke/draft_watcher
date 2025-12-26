# frozen_string_literal: true

class Pick::Csv::ExportsController < ApplicationController
  def create
    picks = Pick.includes(:player, :team, :draft, player: :positions)
    exporter = PickCsvExporter.new(picks)
    csv_content = exporter.generate

    send_data csv_content,
              filename: "picks_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv'
  end
end
