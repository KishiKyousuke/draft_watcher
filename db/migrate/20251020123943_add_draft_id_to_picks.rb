class AddDraftIdToPicks < ActiveRecord::Migration[8.0]
  def change
    add_reference :picks, :draft, null: false, foreign_key: true
  end
end
