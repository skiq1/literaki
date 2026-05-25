module RequestHelpers
  def json
    JSON.parse(response.body)
  end

  def auth_headers(user)
    { "Authorization" => "Bearer #{user.api_token}" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
