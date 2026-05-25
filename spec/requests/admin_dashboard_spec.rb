require "rails_helper"

RSpec.describe "Admin dashboard", type: :request do
  it "renders dashboard with users and games" do
    user = User.create!(username: "marek", api_token: "token")
    Games::CreateService.new(user: user).call

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/html")
    expect(response.body).to include("Literaki Admin")
    expect(response.body).to include("marek")
  end

  it "renders game details" do
    user = User.create!(username: "marek", api_token: "token")
    game = Games::CreateService.new(user: user).call.value

    get "/admin/games/#{game.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Game ##{game.id}")
    expect(response.body).to include("Board")
  end
end
