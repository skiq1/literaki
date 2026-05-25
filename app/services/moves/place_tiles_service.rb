module Moves
  class PlaceTilesService < ApplicationService
    BOARD_SIZE = 15

    def initialize(game:, user:, params:)
      @game = game
      @user = user
      @tiles = normalize_tiles(params[:tiles])
    end

    def call
      turn = ValidateTurnService.new(game: game, user: user).call
      return turn unless turn.success?

      validation_errors = validate_tiles
      return failure(validation_errors) if validation_errors.any?

      move = nil

      Game.transaction do
        score = ScoreService.new(tiles: tiles).call
        updated_board = game.board.merge(board_entries)
        rack_without_tiles = Tiles::RackService.remove_letters(game_player.rack, tiles.map { |tile| tile["letter"] })
        updated_rack, updated_bag = Tiles::RackService.refill(rack_without_tiles, game.bag)

        game_player.update!(
          rack: updated_rack,
          score: game_player.score + score,
          passed_turns_count: 0
        )
        move = ApplyMoveService.new(game: game, user: user, move_type: "place_tiles", tiles: tiles, score: score).call.value
        game.update!(board: updated_board, bag: updated_bag, current_turn_user: next_player)
      end

      success(move)
    rescue ArgumentError => e
      failure(e.message)
    end

    private

    attr_reader :game, :user, :tiles

    def normalize_tiles(raw_tiles)
      Array(raw_tiles).map do |tile|
        item = tile.with_indifferent_access
        {
          "letter" => item[:letter].to_s.upcase,
          "x" => item[:x].to_i,
          "y" => item[:y].to_i
        }
      end
    end

    def validate_tiles
      errors = []
      errors << "Tiles can't be blank" if tiles.empty?
      errors << "Tile is outside the board" if tiles.any? { |tile| outside_board?(tile) }
      errors << "Tile position is already occupied" if tiles.any? { |tile| game.board.key?(position_key(tile)) }
      errors << "Rack does not include all requested tiles" unless Tiles::RackService.contains_letters?(game_player.rack, tiles.map { |tile| tile["letter"] })
      errors
    end

    def outside_board?(tile)
      tile["x"].negative? || tile["x"] >= BOARD_SIZE || tile["y"].negative? || tile["y"] >= BOARD_SIZE
    end

    def board_entries
      tiles.to_h { |tile| [position_key(tile), tile["letter"]] }
    end

    def position_key(tile)
      "#{tile['x']},#{tile['y']}"
    end

    def game_player
      @game_player ||= game.game_players.find_by!(user: user)
    end

    def next_player
      Turns::NextPlayerService.new(game: game, current_user: user).call
    end
  end
end
