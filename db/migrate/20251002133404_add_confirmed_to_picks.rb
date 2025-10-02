class AddConfirmedToPicks < ActiveRecord::Migration[8.0]
  def change
    add_column :picks, :confirmed, :boolean, default: true, null: false
  end
end
