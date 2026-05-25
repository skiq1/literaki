module Tiles
  class BagService
    def self.generate
      Literaki::Tiles::DISTRIBUTION.shuffle
    end

    def self.draw(bag, count)
      letters = Array(bag).dup
      drawn = letters.shift(count)
      [drawn, letters]
    end

    def self.return_tiles(bag, tiles)
      (Array(bag) + Array(tiles)).shuffle
    end
  end
end
