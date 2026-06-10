module Turns
  class NextPlayerService
    def initialize(game:, current_user:)
      @game = game
      @current_user = current_user
    end

    def call
      available_players.detect { |game_player| game_player.user_id != current_user.id }&.user ||
        available_players.detect { |game_player| game_player.user_id == current_user.id }&.user
    end

    private

    attr_reader :game, :current_user

    def available_players
      players = game.game_players.to_a
      return players unless game.time_limit_enabled?

      players.select { |game_player| game_player.remaining_time_ms.positive? }
    end
  end
end
