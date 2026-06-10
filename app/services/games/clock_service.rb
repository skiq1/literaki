module Games
  class ClockService < ApplicationService
    DEFAULT_TIME_LIMIT_MS = 10.minutes.in_milliseconds.to_i

    def initialize(game:, now: Time.current)
      @game = game
      @now = now
    end

    def call
      return success(game) unless game.status == "active"
      return success(game) unless game.time_limit_enabled?

      Game.transaction do
        game.lock!
        sync_current_player_time
        finish_or_advance_turn
      end

      success(game.reload)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :game, :now

    def sync_current_player_time
      return unless game.current_turn_user_id && game.turn_started_at

      player = game.game_players.find_by!(user_id: game.current_turn_user_id)
      elapsed_ms = [ ((now - game.turn_started_at) * 1000).floor, 0 ].max
      remaining_time_ms = [ player.remaining_time_ms - elapsed_ms, 0 ].max
      player.update!(remaining_time_ms: remaining_time_ms)
    end

    def finish_or_advance_turn
      if game.game_players.all? { |player| player.remaining_time_ms <= 0 }
        Games::FinishService.new(game: game, finished_at: now).call
      else
        current_turn_user = next_available_turn_user
        game.update!(current_turn_user: current_turn_user, turn_started_at: now)
      end
    end

    def next_available_turn_user
      current_player = game.game_players.find { |player| player.user_id == game.current_turn_user_id }
      return current_player.user if current_player&.remaining_time_ms&.positive?

      game.game_players.detect { |player| player.remaining_time_ms.positive? }&.user
    end
  end
end
