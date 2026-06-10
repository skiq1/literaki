module Moves
  class ExchangeTilesService < ApplicationService
    def initialize(game:, user:, params:)
      @game = game
      @user = user
      @tiles = Tiles::RackService.normalize_letters(params[:tiles])
    end

    def call
      turn = ValidateTurnService.new(game: game, user: user).call
      return turn unless turn.success?
      return failure("Tiles can't be blank") if tiles.empty?
      return failure("Rack does not include all requested tiles") unless Tiles::RackService.contains_letters?(game_player.rack, tiles)

      move = nil

      Game.transaction do
        rack_after_removal = Tiles::RackService.remove_letters(game_player.rack, tiles)
        drawn, bag_after_draw = Tiles::BagService.draw(game.bag, tiles.size)
        updated_bag = Tiles::BagService.return_tiles(bag_after_draw, tiles)

        game.game_players.each { |player| player.update!(passed_turns_count: 0) }
        game_player.update!(rack: rack_after_removal + drawn)
        move = ApplyMoveService.new(game: game, user: user, move_type: "exchange_tiles", tiles: tiles).call.value
        if next_player
          game.update!(bag: updated_bag, current_turn_user: next_player, turn_started_at: next_turn_started_at)
        else
          game.update!(bag: updated_bag)
          Games::FinishService.new(game: game).call
        end
      end

      success(move)
    rescue ArgumentError => e
      failure(e.message)
    end

    private

    attr_reader :game, :user, :tiles

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
