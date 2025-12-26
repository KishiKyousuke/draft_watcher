# frozen_string_literal: true

class Pick::ImportsController < ApplicationController
  def new; end

  def create
    if params[:import].blank? || params[:import][:csv_file].blank?
      flash[:alert] = 'CSVファイルを選択してください'
      redirect_to new_pick_import_path
      return
    end

    csv_file = params[:import][:csv_file]
    importer = PickCsvImporter.new(csv_file)

    if importer.import
      flash[:notice] = "#{importer.imported_count}件をインポートしました"
      redirect_to picks_path
    else
      flash[:alert] = importer.errors.join('、')
      redirect_to new_pick_import_path
    end
  rescue PickCsvImporter::ImportError => e
    flash[:alert] = e.message
    redirect_to new_pick_import_path
  end
end
