class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  
  before_action :authenticate_request

  private

  def authenticate_customer!
    unless @current_user&.role == 'customer'
      render json: { error: "Only customers can perform this action." }, status: :forbidden
      return
    end
  end

  def authenticate_admin!
    unless @current_user&.role == 'admin'
      render json: { error: "Only admins can perform this action." }, status: :forbidden
      return
    end
  end

  def authenticate_creator!
    unless @current_user&.role == 'creator'
      render json: { error: "Only creators can perform this action." }, status: :forbidden
      return
    end
  end

  def authenticate_request
    header = request.headers["Authorization"]
    header = header.split(" ").last if header.present?
    decoded = JsonWebToken.jwt_decode(header)
    @current_user = User.find(decoded[:user_id]) if decoded
  rescue
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
