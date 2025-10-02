class PlayersController < ApplicationController
  def index
    @players = Player.includes(:positions, :picks).all
  end

  def show
    @player = Player.find(params[:id])
  end

  def new
    @player = Player.new
    @positions = Position.all
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      redirect_to players_path, notice: '選手を登録しました。'
    else
      @positions = Position.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @player = Player.find(params[:id])
    @positions = Position.all
  end

  def update
    @player = Player.find(params[:id])
    if @player.update(player_params)
      redirect_to player_path(@player), notice: '選手情報を更新しました。'
    else
      @positions = Position.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @player = Player.find(params[:id])
    @player.destroy
    redirect_to players_path, notice: '選手を削除しました。'
  end

  private

  def player_params
    params.require(:player).permit(:name, :name_kana, :category, :affiliation, :pitching_batting, :height, :weight, :age, :description, position_ids: [])
  end
end
