module Moves
  class ScoreService
    def initialize(tiles:)
      @tiles = tiles
    end

    def call
      tiles.sum { |tile| Literaki::Tiles::SCORES.fetch(tile.fetch("letter").to_s.upcase, 0) }
    end

    private

    attr_reader :tiles
  end
end
