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
        game.update!(status: "finished", winner: winner, finished_at: Time.current)
        update_player_statistics(winner)
      end

      success(move)
    end

    private

    attr_reader :game, :user

    def next_player
      Turns::NextPlayerService.new(game: game, current_user: user).call
    end

    def update_player_statistics(winner)
      game.game_players.includes(:user).each do |game_player|
        player = game_player.user
        player.increment!(:games_played)
        player.increment!(:games_won) if player.id == winner.id
        player.increment!(:total_score, game_player.score)
      end
    end
  end
end
