module Games
  class StartService < ApplicationService
    def initialize(game:)
      @game = game
    end

    def call
      return failure("Game must be waiting") unless game.status == "waiting"
      return failure("Game requires exactly two players") unless game.game_players.count == 2

      Game.transaction do
        bag = Tiles::BagService.generate

        game.game_players.each do |game_player|
          rack, bag = Tiles::RackService.refill([], bag)
          game_player.update!(rack: rack, score: 0, passed_turns_count: 0)
        end

        game.update!(
          status: "active",
          board: {},
          bag: bag,
          current_turn_user: game.game_players.first.user,
          started_at: Time.current
        )
      end

      success(game.reload)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :game
  end
end
