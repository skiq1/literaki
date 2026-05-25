require "rails_helper"

RSpec.describe Moves::PlaceTilesService do
  it "calculates score from server-side tile values" do
    user = User.create!(username: "marek", api_token: "token-1")
    opponent = User.create!(username: "ania", api_token: "token-2")
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call
    Games::StartService.new(game: game).call
    game.game_players.find_by!(user: user).update!(rack: %w[K O T A E R S])

    result = described_class.new(
      game: game,
      user: user,
      params: { tiles: [{ letter: "K", x: 7, y: 7 }, { letter: "O", x: 8, y: 7 }, { letter: "T", x: 9, y: 7 }] }
    ).call

    expect(result).to be_success
    expect(result.value.score).to eq(5)
  end
end
