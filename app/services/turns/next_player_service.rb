module Turns
  class NextPlayerService
    def initialize(game:, current_user:)
      @game = game
      @current_user = current_user
    end

    def call
      game.game_players.detect { |game_player| game_player.user_id != current_user.id }&.user
    end

    private

    attr_reader :game, :current_user
  end
end
