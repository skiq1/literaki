module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user = User.find_by(api_token: api_token)
      return user if user

      reject_unauthorized_connection
    end

    def api_token
      request.params[:token].presence || bearer_token
    end

    def bearer_token
      match = request.headers["Authorization"].to_s.match(/\ABearer (.+)\z/)
      match&.[](1)
    end
  end
end
