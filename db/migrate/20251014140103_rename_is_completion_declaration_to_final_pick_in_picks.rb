class RenameIsCompletionDeclarationToFinalPickInPicks < ActiveRecord::Migration[8.0]
  def change
    rename_column :picks, :is_completion_declaration, :final_pick
  end
end
