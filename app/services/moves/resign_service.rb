module Moves
  class ResignService < ApplicationService
    def initialize(game:, user:, params: {})
      @game = game
      @user = user
    end

    def call
      turn = ValidateTurnService.new(game: game, user: user).call
      return turn unless turn.success?

      move = nil

      Game.transaction do
        winner = next_player
        move = ApplyMoveService.new(game: game, user: user, move_type: "resign").call.value
        Games::FinishService.new(game: game, winner: winner).call
      end

      success(move)
    end

    private

    attr_reader :game, :user

    def next_player
      game.game_players.detect { |game_player| game_player.user_id != user.id }&.user
    end
  end
end
