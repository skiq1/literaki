require "rails_helper"

RSpec.describe Game, type: :model do
  it "validates status" do
    game = described_class.new(status: "broken")

    expect(game).not_to be_valid
    expect(game.errors[:status]).to be_present
  end
end
