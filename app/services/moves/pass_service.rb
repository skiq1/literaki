module Moves
  class PassService < ApplicationService
    def initialize(game:, user:, params: {})
      @game = game
      @user = user
    end

    def call
      turn = ValidateTurnService.new(game: game, user: user).call
      return turn unless turn.success?

      move = nil

      Game.transaction do
        game_player.update!(passed_turns_count: game_player.passed_turns_count + 1)
        move = ApplyMoveService.new(game: game, user: user, move_type: "pass").call.value
        if Games::PassStreakService.new(game: game).finished? || next_player.nil?
          Games::FinishService.new(game: game).call
        else
          game.update!(current_turn_user: next_player, turn_started_at: next_turn_started_at)
        end
      end

      success(move)
    end

    private

    attr_reader :game, :user

    def game_player
      @game_player ||= game.game_players.find_by!(user: user)
    end

    def next_player
      Turns::NextPlayerService.new(game: game, current_user: user).call
    end

    def next_turn_started_at
      game.time_limit_enabled? ? Time.current : nil
    end
  end
end
