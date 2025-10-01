class RenameDraftResultsToPicks < ActiveRecord::Migration[8.0]
  def change
    rename_table :draft_results, :picks
  end
end
