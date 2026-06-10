module Games
  class PassStreakService
    MAX_CONSECUTIVE_PASSES_PER_PLAYER = 3

    def initialize(game:)
      @game = game
    end

    def finished?
      game.game_players.reload.all? { |player| player.passed_turns_count >= MAX_CONSECUTIVE_PASSES_PER_PLAYER }
    end

    private

    attr_reader :game
  end
end
