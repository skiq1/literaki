class GameSerializer
  def initialize(game, current_user:)
    @game = game
    @current_user = current_user
  end

  def as_json(*)
    {
      id: game.id,
      status: game.status,
      board: game.board,
      players: players,
      current_turn_user_id: game.current_turn_user_id,
      winner_id: game.winner_id,
      started_at: game.started_at,
      finished_at: game.finished_at,
      moves: game.moves.order(:created_at).map { |move| MoveSerializer.render(move) }
    }
  end

  private

  attr_reader :game, :current_user

  def players
    game.game_players.includes(:user).map do |game_player|
      payload = {
        id: game_player.user.id,
        username: game_player.user.username,
        score: game_player.score,
        position: game_player.position,
        passed_turns_count: game_player.passed_turns_count
      }
      payload[:rack] = game_player.rack if game_player.user_id == current_user.id
      payload
    end
  end
end
