class Api::V1::PurchasesController < ApplicationController
  before_action :authenticate_request
  before_action :authenticate_customer!, only: [:create]
  skip_before_action :verify_authenticity_token


  def index
    if @current_user&.role == 'admin'
      purchases = Purchase.includes(:asset, :customer)
    elsif @current_user&.role == 'creator'
      assets = Asset.where(creator_id: @current_user.id)
      purchases = Purchase.includes(:asset, :customer).where(asset_id: assets.pluck(:id))
    else # customer
      purchases = Purchase.includes(:asset, :customer).where(customer_id: @current_user.id)
    end

    render json: purchases.map { |purchase|
      {
        purchase_id: purchase.id,
        purchase_amount: purchase.amount,
        customer: {
          id: purchase.customer.id,
          name: purchase.customer.name,
          email: purchase.customer.email
        },
        asset: {
          id: purchase.asset.id,
          title: purchase.asset.title,
          description: purchase.asset.description
        },
        creator: {
          id: purchase.asset.creator.id,
          name: purchase.asset.creator.name,
          email: purchase.asset.creator.email
        }
      }
    }, status: :ok
  end



  def create
    asset = Asset.find(params[:asset_id])
    purchase = Purchase.new(customer_id: @current_user.id, asset_id: asset.id)
    if purchase.save
      render json: {
        message: "Purchase successful",
        purchase: purchase
      }, status: :created
    else
      render json: {
        error: "Purchase failed",
        details: purchase.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

end
