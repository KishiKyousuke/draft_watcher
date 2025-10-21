class DraftsController < ApplicationController
  before_action :set_draft, only: [:show, :edit, :update, :destroy]

  def index
    @drafts = Draft.all.order(year: :desc)
  end

  def show
    @team_standings = @draft.team_standings.includes(:team).order(:rank)

    # 各球団の指名結果を取得（N+1対策）
    @picks_by_team = @draft.picks
                           .includes(:player, :team)
                           .group_by(&:team_id)
                           .transform_values { |picks| picks.sort_by(&:draft_round) }
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
