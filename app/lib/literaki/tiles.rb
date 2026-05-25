module Literaki
  module Tiles
    SCORES = {
      "A" => 1, "E" => 1, "I" => 1, "N" => 1, "O" => 1, "R" => 1, "S" => 1, "W" => 1, "Z" => 1,
      "C" => 2, "D" => 2, "K" => 2, "L" => 2, "M" => 2, "P" => 2, "T" => 2, "Y" => 2,
      "B" => 3, "G" => 3, "H" => 3, "J" => 3, "Ł" => 3, "U" => 3,
      "Ą" => 5, "Ę" => 5, "F" => 5, "Ó" => 5, "Ś" => 5, "Ż" => 5,
      "Ć" => 6,
      "Ń" => 7,
      "Ź" => 9
    }.freeze

    DISTRIBUTION = SCORES.keys.flat_map { |letter| Array.new([10 - SCORES.fetch(letter), 1].max, letter) }.freeze
  end
end
