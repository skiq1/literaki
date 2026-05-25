module Tiles
  class RackService
    def self.normalize_letters(letters)
      Array(letters).map { |letter| letter.to_s.upcase }
    end

    def self.contains_letters?(rack, letters)
      remaining = normalize_letters(rack)

      normalize_letters(letters).all? do |letter|
        index = remaining.index(letter)
        index ? remaining.delete_at(index) : false
      end
    end

    def self.remove_letters(rack, letters)
      remaining = normalize_letters(rack)

      normalize_letters(letters).each do |letter|
        index = remaining.index(letter)
        raise ArgumentError, "Rack does not include #{letter}" unless index

        remaining.delete_at(index)
      end

      remaining
    end

    def self.refill(rack, bag, size: 7)
      current = normalize_letters(rack)
      needed = [size - current.size, 0].max
      drawn, updated_bag = BagService.draw(bag, needed)
      [current + drawn, updated_bag]
    end
  end
end
