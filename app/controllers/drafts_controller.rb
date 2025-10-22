class DraftsController < ApplicationController
  before_action :set_draft, only: [:show, :edit, :update, :destroy]

  def index
    @drafts = Draft.all.order(year: :desc)
  end

  def show
    leagues = @draft.starts_with_central? ? [Team.leagues[:central], Team.leagues[:pacific]] : [Team.leagues[:pacific], Team.leagues[:central]]
    @team_standings = @draft.team_standings
                            .eager_load(:team)
                            .order(rank: :desc)
                            .in_order_of(:league, leagues)

    # 各球団の指名結果を取得（N+1対策）
    # 支配下指名→育成指名の順、各グループ内で順位昇順に並び替え
    @picks_by_team = @draft.picks
                           .includes(:player, :team)
                           .group_by(&:team_id)
                           .transform_values { |picks| picks.sort_by { |p| [p.training_player ? 1 : 0, p.draft_round] } }
  end

  def new
    @draft = Draft.new
    @teams = Team.all.order(:league, :id)
    # 全チームに対してteam_standingsを事前構築
    @teams.each do |team|
      @draft.team_standings.build(team: team)
    end
  end

  def create
    @draft = Draft.new(draft_params)

    if @draft.save
      redirect_to @draft, notice: 'ドラフト会議を作成しました。'
    else
      @teams = Team.all.order(:league, :id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @teams = Team.all.order(:league, :id)
  end

  def update
    if @draft.update(draft_params)
      redirect_to @draft, notice: 'ドラフト会議を更新しました。'
    else
      @teams = Team.all.order(:league, :id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @draft.destroy
    redirect_to drafts_url, notice: 'ドラフト会議を削除しました。'
  end

  private

  def set_draft
    @draft = Draft.find(params[:id])
  end

  def draft_params
    params.require(:draft).permit(
      :year, :starts_with_central, :virtual,
      team_standings_attributes: [:id, :team_id, :rank]
    )
  end
end
