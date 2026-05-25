require "rails_helper"

RSpec.describe "Auth API", type: :request do
  describe "POST /api/v1/auth" do
    it "creates a user and returns token" do
      post "/api/v1/auth", params: { username: "marek" }

      expect(response).to have_http_status(:created)
      expect(json.dig("user", "username")).to eq("marek")
      expect(json["token"]).to be_present
      expect(User.count).to eq(1)
    end
  end

  describe "GET /api/v1/me" do
    it "returns current user for valid token" do
      user = User.create!(username: "marek", api_token: "token")

      get "/api/v1/me", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(user.id)
      expect(json["games_played"]).to eq(0)
    end

    it "returns unauthorized without token" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Unauthorized")
    end
  end
end
