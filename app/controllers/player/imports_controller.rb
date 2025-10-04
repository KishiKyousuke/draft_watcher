class Player::ImportsController < ApplicationController
  def new
  end

  def create
    unless params[:file].present?
      redirect_to new_player_import_path, alert: 'ファイルを選択してください。'
      return
    end

    importer = PlayerCsvImporter.new(params[:file])

    if importer.import
      redirect_to players_path, notice: "#{importer.imported_count}件の選手をインポートしました。"
    else
      redirect_to new_player_import_path, alert: importer.errors.join(', ')
    end
  end
end
