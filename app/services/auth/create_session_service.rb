module Auth
  class CreateSessionService < ApplicationService
    def initialize(username:)
      @username = username.to_s.strip
    end

    def call
      return failure("Username can't be blank") if username.blank?

      user = User.create!(username: username, api_token: generate_unique_token)
      success(user)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :username

    def generate_unique_token
      loop do
        token = SecureRandom.urlsafe_base64(32)
        return token unless User.exists?(api_token: token)
      end
    end
  end
end
