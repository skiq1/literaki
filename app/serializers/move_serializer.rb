class MoveSerializer
  def self.render(move)
    {
      id: move.id,
      game_id: move.game_id,
      user_id: move.user_id,
      move_type: move.move_type,
      tiles: move.tiles,
      words: move.words,
      score: move.score,
      created_at: move.created_at
    }
  end
end
