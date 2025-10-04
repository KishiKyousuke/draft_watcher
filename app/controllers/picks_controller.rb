class PicksController < ApplicationController
  def index
    @picks = Pick.includes(:player, :team).page(params[:page]).per(50)
  end

  def new
    @pick = Pick.new
    @pick.player_id = params[:player_id]
    @selected_player = Player.find(params[:player_id])
    @teams = Team.all
  end

  def create
    @pick = Pick.new(pick_params)

    if @pick.save
      redirect_to player_path(@pick.player), notice: t('notices.pick_created')
    else
      @selected_player = Player.find(@pick.player_id)
      @teams = Team.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @pick = Pick.find(params[:id])
    @selected_player = @pick.player
    @teams = Team.all
  end

  def update
    @pick = Pick.find(params[:id])
    if @pick.update(pick_params)
      redirect_to picks_path, notice: t('notices.pick_updated')
    else
      @selected_player = @pick.player
      @teams = Team.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pick = Pick.find(params[:id])
    @pick.destroy
    redirect_to picks_path, notice: t('notices.pick_deleted')
  end

  private

  def pick_params
    params.require(:pick).permit(:player_id, :team_id, :year, :draft_round, :training_player, :confirmed)
  end
end
