module Games
  class ClockSweepJob < ApplicationJob
    queue_as :default

    def perform
      Game.where(status: "active", time_limit_enabled: true).find_each do |game|
        previous_status = game.status
        previous_turn_user_id = game.current_turn_user_id

        result = Games::ClockService.new(game: game).call
        next unless result.success?

        updated_game = result.value
        next unless updated_game.status != previous_status || updated_game.current_turn_user_id != previous_turn_user_id

        Games::BroadcastService.call(game: updated_game, event: Games::BroadcastService::EVENT_GAME_UPDATED)
      end
    end
  end
end
