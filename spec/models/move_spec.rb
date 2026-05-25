require "rails_helper"

RSpec.describe Move, type: :model do
  it "validates move type" do
    user = User.create!(username: "marek", api_token: "token")
    game = Game.create!

    move = described_class.new(game: game, user: user, move_type: "invalid")

    expect(move).not_to be_valid
  end
end
