class Api::V1::PurchasesController < ApplicationController
  before_action :authenticate_request
  before_action :authenticate_customer!, only: [:create]
  skip_before_action :verify_authenticity_token

  def index
    page = params[:page].present? ? params[:page].to_i : 1
    limit = params[:limit].present? ? params[:limit].to_i : 10
    
    service = PurchaseService.new(@current_user)
    result = service.list_purchases(page: page, limit: limit)
    
    render json: result, status: :ok
  end

  def create
    service = PurchaseService.new(@current_user)
    result = service.create_purchase(params[:asset_id])
    
    if result[:success]
      render json: {
        message: "Purchase successful",
        purchase: result[:purchase]
      }, status: :created
    else
      render json: {
        error: "Purchase failed",
        details: result[:errors]
      }, status: :unprocessable_entity
    end
  end
end