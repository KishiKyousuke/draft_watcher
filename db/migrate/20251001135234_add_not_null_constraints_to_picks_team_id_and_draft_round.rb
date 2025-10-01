class AddNotNullConstraintsToPicksTeamIdAndDraftRound < ActiveRecord::Migration[8.0]
  def change
    change_column_null :picks, :team_id, false
    change_column_null :picks, :draft_round, false
  end
end
