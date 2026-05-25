require "rails_helper"

RSpec.describe User, type: :model do
  it "requires username and unique api token" do
    described_class.create!(username: "marek", api_token: "token")

    user = described_class.new(username: "", api_token: "token")

    expect(user).not_to be_valid
    expect(user.errors[:username]).to be_present
    expect(user.errors[:api_token]).to be_present
  end

  it "allows duplicate usernames" do
    described_class.create!(username: "marek", api_token: "token-1")
    user = described_class.new(username: "marek", api_token: "token-2")

    expect(user).to be_valid
  end
end
