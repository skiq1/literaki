class UserSerializer
  def self.auth(user)
    {
      id: user.id,
      username: user.username
    }
  end

  def self.me(user)
    {
      id: user.id,
      username: user.username,
      games_played: user.games_played,
      games_won: user.games_won,
      total_score: user.total_score
    }
  end
end
