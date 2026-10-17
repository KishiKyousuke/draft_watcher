class Players::SearchesController < ApplicationController
  def index
    @players = if params[:query].present?
                 players = Player.where('name LIKE ? OR name_kana LIKE ?',
                                        "%#{params[:query]}%",
                                        "%#{params[:query]}%")
                 # ドラフトが指定されていればその年度の候補選手に絞り込む
                 draft = Draft.find_by(id: params[:draft_id]) if params[:draft_id].present?
                 players = players.joins(:player_draft_years).where(player_draft_years: { year: draft.year }) if draft
                 players.order(:name_kana).limit(20)
    else
                 Player.none
    end

    respond_to do |format|
      format.turbo_stream
      format.json { render json: @players }
    end
  end
end
