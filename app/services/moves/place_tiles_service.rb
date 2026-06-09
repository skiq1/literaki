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

      words = formed_words
      word_validation = Words::ValidateService.new(words: words).call
      return word_validation unless word_validation.success?

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
        move = ApplyMoveService.new(game: game, user: user, move_type: "place_tiles", tiles: tiles, words: words, score: score).call.value
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
      errors << "Tiles must be in a single row or column" unless single_line?
      errors << "Tiles must form one contiguous word" if single_line? && !contiguous_word?
      errors
    end

    def formed_words
      words = [ main_word, *cross_words ].select { |word| word.length > 1 }
      words.presence || [ main_word ]
    end

    def main_word
      if horizontal_move?
        word_at(tiles.first["x"], tiles.first["y"], 1, 0)
      else
        word_at(tiles.first["x"], tiles.first["y"], 0, 1)
      end
    end

    def cross_words
      tiles.filter_map do |tile|
        word = if horizontal_move?
          word_at(tile["x"], tile["y"], 0, 1)
        else
          word_at(tile["x"], tile["y"], 1, 0)
        end
        word if word.length > 1
      end
    end

    def word_at(x, y, dx, dy)
      board = board_after_move
      start_x = x
      start_y = y

      while board.key?("#{start_x - dx},#{start_y - dy}")
        start_x -= dx
        start_y -= dy
      end

      letters = []
      current_x = start_x
      current_y = start_y

      while board.key?("#{current_x},#{current_y}")
        letters << board.fetch("#{current_x},#{current_y}")
        current_x += dx
        current_y += dy
      end

      letters.join
    end

    def contiguous_word?
      main_word_positions = if horizontal_move?
        word_positions_at(tiles.first["x"], tiles.first["y"], 1, 0)
      else
        word_positions_at(tiles.first["x"], tiles.first["y"], 0, 1)
      end

      tile_positions.all? { |position| main_word_positions.include?(position) }
    end

    def word_positions_at(x, y, dx, dy)
      board = board_after_move
      start_x = x
      start_y = y

      while board.key?("#{start_x - dx},#{start_y - dy}")
        start_x -= dx
        start_y -= dy
      end

      positions = []
      current_x = start_x
      current_y = start_y

      while board.key?("#{current_x},#{current_y}")
        positions << "#{current_x},#{current_y}"
        current_x += dx
        current_y += dy
      end

      positions
    end

    def horizontal_move?
      tiles.size == 1 || tiles.map { |tile| tile["y"] }.uniq.one?
    end

    def vertical_move?
      tiles.size == 1 || tiles.map { |tile| tile["x"] }.uniq.one?
    end

    def single_line?
      horizontal_move? || vertical_move?
    end

    def board_after_move
      @board_after_move ||= game.board.merge(board_entries)
    end

    def tile_positions
      @tile_positions ||= tiles.map { |tile| position_key(tile) }
    end

    def outside_board?(tile)
      tile["x"].negative? || tile["x"] >= BOARD_SIZE || tile["y"].negative? || tile["y"] >= BOARD_SIZE
    end

    def board_entries
      tiles.to_h { |tile| [ position_key(tile), tile["letter"] ] }
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
