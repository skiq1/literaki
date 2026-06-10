module Api
  module V1
    class GamesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_game, only: %i[show join start]
      before_action :ensure_player!, only: %i[show start]

      def index
        sync_active_games(current_user.games)
        games = current_user.games.includes(:game_players, :moves).order(created_at: :desc)
        render json: games.map { |game| GameSerializer.new(game, current_user: current_user).as_json }
      end

      def create
        result = Games::CreateService.new(user: current_user, time_limit_enabled: create_params.fetch(:time_limit_enabled, true)).call
        render_service_result(result, status: :created, event: Games::BroadcastService::EVENT_GAME_CREATED)
      end

      def show
        sync_game_clock(@game)
        render json: GameSerializer.new(@game, current_user: current_user).as_json
      end

      def join
        result = Games::JoinService.new(game: @game, user: current_user).call
        render_service_result(result, event: Games::BroadcastService::EVENT_GAME_UPDATED)
      end

      def start
        result = Games::StartService.new(game: @game).call
        render_service_result(result, event: Games::BroadcastService::EVENT_GAME_UPDATED)
      end

      private

      def set_game
        @game = Game.find(params[:id])
      end

      def ensure_player!
        return if @game.game_players.exists?(user: current_user)

        render_errors([ "Forbidden" ], status: :forbidden)
      end

      def render_service_result(result, status: :ok, event: nil)
        if result.success?
          Games::BroadcastService.call(game: result.value, event: event) if event
          render json: GameSerializer.new(result.value, current_user: current_user).as_json, status: status
        else
          render_errors(result.errors)
        end
      end

      def create_params
        params.permit(:time_limit_enabled)
      end

      def sync_game_clock(game)
        previous_status = game.status
        previous_turn_user_id = game.current_turn_user_id

        result = Games::ClockService.new(game: game).call
        return unless result.success?

        updated_game = result.value
        if updated_game.status != previous_status || updated_game.current_turn_user_id != previous_turn_user_id
          Games::BroadcastService.call(game: updated_game, event: Games::BroadcastService::EVENT_GAME_UPDATED)
        end
      end

      def sync_active_games(games)
        games.where(status: "active").find_each { |game| sync_game_clock(game) }
      end
    end
  end
end
