# frozen_string_literal: true

class Pick::Csv::ImportsController < ApplicationController
  def create
    if params[:import].blank? || params[:import][:csv_file].blank?
      flash[:alert] = 'CSVファイルを選択してください'
      redirect_to new_pick_csv_path
      return
    end

    csv_file = params[:import][:csv_file]
    importer = PickCsvImporter.new(csv_file)

    if importer.import
      message_parts = []
      message_parts << "#{importer.imported_count}件を新規作成しました" if importer.imported_count > 0
      message_parts << "#{importer.skipped_count}件をスキップしました（既存データ）" if importer.skipped_count > 0

      flash[:notice] = message_parts.join('、')
      redirect_to picks_path
    else
      flash[:alert] = importer.errors.join('、')
      redirect_to new_pick_csv_path
    end
  rescue PickCsvImporter::ImportError => e
    flash[:alert] = e.message
    redirect_to new_pick_csv_path
  end
end
