class Api::V1::AuthenticationController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:login, :register]

  def login
    @user = User.find_by(email: params[:email])

    if @user&.authenticate(params[:password])
      token = JsonWebToken.jwt_encode(user_id: @user.id, user_role:@user.role)
      render json: { token: token }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def register
    if params[:password] != params[:password_confirmation]
      render json: { error: "Password confirmation doesn't match" }, status: :unprocessable_entity
      return
    end

    user = User.new(register_params)

    if user.save
      token = JsonWebToken.jwt_encode(user_id: user.id, user_role: user.role)
      render json: { token: token, user: user }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end


  private

  def register_params
    params.permit(:name, :email, :password, :role)
  end
end
