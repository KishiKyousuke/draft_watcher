class PlayersController < ApplicationController
  def index
    @players = Player.includes(:positions, :draft_results).all
  end
end
