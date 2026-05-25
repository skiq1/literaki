module Api
  module V1
    class MovesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_game
      before_action :ensure_player!

      def index
        moves = @game.moves.order(:created_at)
        render json: moves.map { |move| MoveSerializer.render(move) }
      end

      def create
        result = Moves::CreateService.new(game: @game, user: current_user, params: move_params.to_h).call

        if result.success?
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

        render_errors(["Forbidden"], status: :forbidden)
      end

      def move_params
        params.permit!.to_h.slice("move_type", "tiles")
      end
    end
  end
end
