class Api::V1::UsersController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [ :create ]
    before_action :set_user, only: [ :show, :update, :destroy ]

    # GET /users
    def index
        @users = User.all
        render json: @users
    end

    # GET /users/:id
    def show
        render json: @user, status: :ok
    end


    # POST /users
    def create
        @user = User.new(user_params)

        if @user.save
            render json: @user, status: :created
        else
            render json: @user.errors, status: :unprocessable_entity
        end
    end

    #    # PATCH/PUT /users/:id
    def update
        if @user.update(user_params)
            render json: @user
        else
            render json: @user.errors, status: :unprocessable_entity
        end
    end

    # DELETE /users/:id
    def destroy
        @user.destroy
        head :no_content
    end

    private
    def user_params
        params.permit(:name, :email, :password, :role)
    end
    def set_user
        @user = User.find(params[:id])
    end
end
