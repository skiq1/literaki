module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      def me
        render json: UserSerializer.me(current_user)
      end
    end
  end
end
