class PlayersController < ApplicationController
  def index
    @players = Player.includes(:positions, :picks)

    # 名前・ふりがな検索
    if params[:query].present?
      @players = @players.where('players.name LIKE ? OR players.name_kana LIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
    end

    # カテゴリ検索
    if params[:category].present?
      @players = @players.where(category: params[:category])
    end

    # ポジション検索
    if params[:position_id].present?
      @players = @players.joins(:positions).where(positions: { id: params[:position_id] })
    end

    @players = @players.distinct.page(params[:page]).per(50)
    @positions = Position.all
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
