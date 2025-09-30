class PlayersController < ApplicationController
  def index
    @players = Player.includes(:positions, :draft_results).all
  end

  def new
    @player = Player.new
    @positions = Position.all
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      redirect_to players_path, notice: "選手を登録しました。"
    else
      @positions = Position.all
      render :new, status: :unprocessable_entity
    end
  end

  private

  def player_params
    params.require(:player).permit(:name, :name_kana, :category, :affiliation, :pitching_batting, :height, :weight, :age, :description, position_ids: [])
  end
end
