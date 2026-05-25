class ApplicationController < ActionController::API
  attr_reader :current_user

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def authenticate_user!
    token = bearer_token
    @current_user = token.present? ? User.find_by(api_token: token) : nil

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    match = header.match(/\ABearer (.+)\z/)
    match&.[](1)
  end

  def render_not_found
    render json: { errors: ["Not found"] }, status: :not_found
  end

  def render_errors(errors, status: :unprocessable_entity)
    render json: { errors: Array(errors) }, status: status
  end
end
