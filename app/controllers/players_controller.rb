class PlayersController < ApplicationController
  def index
    @players = Player.includes(:positions, :player_draft_years, picks: :draft)

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

    # ドラフト候補年検索
    if params[:draft_year].present?
      @players = @players.joins(:player_draft_years).where(player_draft_years: { year: params[:draft_year] })
    end

    # 未指名のみフィルター（本番ドラフトで確定した指名がない選手）
    if params[:undrafted_only] == '1'
      @players = @players.left_joins(picks: :draft)
                         .group('players.id')
                         .having('COUNT(CASE WHEN drafts.virtual = ? AND picks.confirmed = ? THEN 1 END) = 0', false, true)
    end

    @players = @players.left_joins(:player_draft_years)
                       .group('players.id')
                       .order(Arel.sql(players_order_sql))
                       .distinct
                       .page(params[:page]).per(50)
    @positions = Position.all
    @draft_years = PlayerDraftYear.distinct.order(year: :desc).pluck(:year)
  end

  def show
    @player = Player.find(params[:id])
    @pick_results = @player.picks.official.includes(:team, :draft)
  end

  def new
    @player = Player.new(draft_years_text: Date.current.year.to_s)
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

  SORT_DIRECTIONS = { 'created_at_asc' => 'ASC', 'created_at_desc' => 'DESC' }.freeze

  # 最新の候補年のplayer_draft_yearの登録日時
  LATEST_DRAFT_YEAR_CREATED_AT_SQL = <<~SQL.squish.freeze
    (SELECT latest.created_at FROM player_draft_years latest
     WHERE latest.player_id = players.id ORDER BY latest.year DESC LIMIT 1)
  SQL

  def players_order_sql
    latest_created_at = LATEST_DRAFT_YEAR_CREATED_AT_SQL

    # 候補年の古い順（候補年がない選手は末尾）、同じなら最新の候補年の登録日時の古い順、さらに同じならIDで並べる
    if params[:sort] == 'draft_year_asc'
      return 'MAX(player_draft_years.year) IS NULL, MAX(player_draft_years.year) ASC, ' \
             "#{latest_created_at} ASC, players.id ASC"
    end

    direction = SORT_DIRECTIONS[params[:sort]]
    return 'MAX(player_draft_years.year) DESC, players.created_at DESC' if direction.nil?

    # 最新の候補年の登録日時（候補年がない選手は末尾）、同じならIDで並べる
    "#{latest_created_at} IS NULL, #{latest_created_at} #{direction}, players.id #{direction}"
  end

  def player_params
    params.require(:player).permit(:name, :name_kana, :category, :affiliation, :pitching_batting, :height, :weight, :age, :description, :draft_years_text, position_ids: [])
  end
end
