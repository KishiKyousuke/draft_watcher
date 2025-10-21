class PicksController < ApplicationController
  def index
    @picks = Pick.includes(:player, :team, :draft).page(params[:page]).per(50)
  end

  def new
    # パラメータを収集
    pick_params = {}
    pick_params[:draft_id] = params[:draft_id] if params[:draft_id].present?
    pick_params[:team_id] = params[:team_id] if params[:team_id].present?
    pick_params[:player_id] = params[:player_id] if params[:player_id].present?

    @pick = Pick.new(pick_params)

    # ドラフト詳細からの遷移パラメータを処理
    if params[:draft_id].present?
      @draft = Draft.find(params[:draft_id])

      # 指名順位を自動計算
      if params[:team_id].present?
        @pick.draft_round = @draft.next_draft_round_for_team(Team.find(params[:team_id]))
      end
    end

    # 選手検索からの遷移
    if params[:player_id].present?
      @selected_player = Player.find(params[:player_id])
    end

    @teams = Team.all
    @drafts = Draft.all.order(year: :desc)
  end

  def create
    @pick = Pick.new(pick_params)

    if @pick.save
      # ドラフト詳細から作成した場合はドラフト詳細にリダイレクト
      if @pick.draft.present?
        redirect_to draft_path(@pick.draft), notice: t('notices.pick_created')
      else
        redirect_to player_path(@pick.player), notice: t('notices.pick_created')
      end
    else
      @selected_player = Player.find(@pick.player_id) if @pick.player_id.present?
      @draft = Draft.find(@pick.draft_id) if @pick.draft_id.present?
      @teams = Team.all
      @drafts = Draft.all.order(year: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @pick = Pick.find(params[:id])
    @selected_player = @pick.player
    @draft = @pick.draft
    @teams = Team.all
    @drafts = Draft.all.order(year: :desc)
  end

  def update
    @pick = Pick.find(params[:id])
    if @pick.update(pick_params)
      # ドラフト詳細から編集した場合はドラフト詳細にリダイレクト
      if @pick.draft.present?
        redirect_to draft_path(@pick.draft), notice: t('notices.pick_updated')
      else
        redirect_to picks_path, notice: t('notices.pick_updated')
      end
    else
      @selected_player = @pick.player if @pick.player_id.present?
      @draft = @pick.draft if @pick.draft_id.present?
      @teams = Team.all
      @drafts = Draft.all.order(year: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pick = Pick.find(params[:id])
    draft = @pick.draft
    @pick.destroy

    # ドラフト詳細から削除した場合はドラフト詳細にリダイレクト
    if draft.present?
      redirect_to draft_path(draft), notice: t('notices.pick_deleted')
    else
      redirect_to picks_path, notice: t('notices.pick_deleted')
    end
  end

  private

  def pick_params
    params.require(:pick).permit(:player_id, :team_id, :draft_id, :draft_round, :training_player, :confirmed, :final_pick)
  end
end
