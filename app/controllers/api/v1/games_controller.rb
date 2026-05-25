module Api
  module V1
    class GamesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_game, only: %i[show join start]
      before_action :ensure_player!, only: %i[show start]

      def index
        games = current_user.games.includes(:game_players, :moves).order(created_at: :desc)
        render json: games.map { |game| GameSerializer.new(game, current_user: current_user).as_json }
      end

      def create
        result = Games::CreateService.new(user: current_user).call
        render_service_result(result, status: :created)
      end

      def show
        render json: GameSerializer.new(@game, current_user: current_user).as_json
      end

      def join
        result = Games::JoinService.new(game: @game, user: current_user).call
        render_service_result(result)
      end

      def start
        result = Games::StartService.new(game: @game).call
        render_service_result(result)
      end

      private

      def set_game
        @game = Game.find(params[:id])
      end

      def ensure_player!
        return if @game.game_players.exists?(user: current_user)

        render_errors(["Forbidden"], status: :forbidden)
      end

      def render_service_result(result, status: :ok)
        if result.success?
          render json: GameSerializer.new(result.value, current_user: current_user).as_json, status: status
        else
          render_errors(result.errors)
        end
      end
    end
  end
end
