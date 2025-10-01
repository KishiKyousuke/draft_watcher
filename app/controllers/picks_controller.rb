class PicksController < ApplicationController
  def index
    @picks = Pick.includes(:player, :team).all
  end

  def new
    @pick = Pick.new
    if params[:player_id].present?
      @pick.player_id = params[:player_id]
      @selected_player = Player.find(params[:player_id])
    end
    @players = Player.all
    @teams = Team.all
  end

  def create
    @pick = Pick.new(pick_params)

    if @pick.save
      redirect_to picks_path, notice: t('notices.pick_created')
    else
      @players = Player.all
      @teams = Team.all
      render :new, status: :unprocessable_entity
    end
  end

  private

  def pick_params
    params.require(:pick).permit(:player_id, :team_id, :year, :draft_round, :training_player)
  end
end
