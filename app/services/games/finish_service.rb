module Games
  class FinishService < ApplicationService
    def initialize(game:, winner: nil, finished_at: Time.current)
      @game = game
      @winner = winner
      @finished_at = finished_at
    end

    def call
      return success(game) if game.status == "finished"

      game.update!(status: "finished", winner: winner, finished_at: finished_at, current_turn_user: nil)
      update_player_statistics
      success(game)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :game, :winner, :finished_at

    def update_player_statistics
      game.game_players.includes(:user).each do |game_player|
        player = game_player.user
        player.increment!(:games_played)
        player.increment!(:games_won) if winner && player.id == winner.id
        player.increment!(:total_score, game_player.score)
      end
    end
  end
end
