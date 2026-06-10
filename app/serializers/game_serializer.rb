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
      time_limit_enabled: game.time_limit_enabled,
      turn_started_at: game.turn_started_at,
      current_turn_deadline_at: current_turn_deadline_at,
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
        passed_turns_count: game_player.passed_turns_count,
        remaining_time_ms: remaining_time_ms_for(game_player)
      }
      payload[:rack] = game_player.rack if game_player.user_id == current_user.id
      payload
    end
  end

  def current_turn_deadline_at
    return unless game.time_limit_enabled? && game.turn_started_at && game.current_turn_user_id

    player = game.game_players.find { |game_player| game_player.user_id == game.current_turn_user_id }
    return unless player

    game.turn_started_at + (player.remaining_time_ms / 1000.0).seconds
  end

  def remaining_time_ms_for(game_player)
    return nil unless game.time_limit_enabled?
    return game_player.remaining_time_ms unless game.status == "active"
    return game_player.remaining_time_ms unless game_player.user_id == game.current_turn_user_id
    return game_player.remaining_time_ms unless game.turn_started_at

    elapsed_ms = [ ((Time.current - game.turn_started_at) * 1000).floor, 0 ].max
    [ game_player.remaining_time_ms - elapsed_ms, 0 ].max
  end
end
