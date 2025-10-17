class Players::SearchesController < ApplicationController
  def index
    @players = if params[:query].present?
                 Player.where("name LIKE ? OR name_kana LIKE ?",
                             "%#{params[:query]}%",
                             "%#{params[:query]}%")
                       .order(:name_kana)
                       .limit(20)
               else
                 Player.none
               end

    respond_to do |format|
      format.turbo_stream
      format.json { render json: @players }
    end
  end
end
