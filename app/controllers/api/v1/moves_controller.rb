module Api
  module V1
    class MovesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_game
      before_action :ensure_player!
      before_action :sync_game_clock

      def index
        moves = @game.moves.order(:created_at)
        render json: moves.map { |move| MoveSerializer.render(move) }
      end

      def create
        result = Moves::CreateService.new(game: @game, user: current_user, params: move_params.to_h).call

        if result.success?
          Games::BroadcastService.call(
            game: @game,
            event: Games::BroadcastService::EVENT_MOVE_CREATED,
            move: result.value
          )
          render json: MoveSerializer.render(result.value), status: :created
        else
          render_errors(result.errors)
        end
      end

      private

      def set_game
        @game = Game.find(params[:game_id])
      end

      def ensure_player!
        return if @game.game_players.exists?(user: current_user)

        render_errors([ "Forbidden" ], status: :forbidden)
      end

      def move_params
        params.permit!.to_h.slice("move_type", "tiles")
      end

      def sync_game_clock
        previous_status = @game.status
        previous_turn_user_id = @game.current_turn_user_id

        result = Games::ClockService.new(game: @game).call
        return unless result.success?

        @game = result.value
        if @game.status != previous_status || @game.current_turn_user_id != previous_turn_user_id
          Games::BroadcastService.call(game: @game, event: Games::BroadcastService::EVENT_GAME_UPDATED)
        end
      end
    end
  end
end
