class Player::ExportsController < ApplicationController
  def new
  end

  def create
    exporter = PlayerCsvExporter.new
    csv_data = exporter.generate

    send_data csv_data, filename: "players_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv", type: 'text/csv'
  end
end
