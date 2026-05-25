module Api
  module V1
    class AuthController < ApplicationController
      def create
        result = Auth::CreateSessionService.new(username: params[:username]).call

        if result.success?
          render json: { user: UserSerializer.auth(result.value), token: result.value.api_token }, status: :created
        else
          render_errors(result.errors)
        end
      end
    end
  end
end
