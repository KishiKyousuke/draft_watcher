class AddIsCompletionDeclarationToPicks < ActiveRecord::Migration[8.0]
  def change
    add_column :picks, :is_completion_declaration, :boolean, default: false, null: false
  end
end
