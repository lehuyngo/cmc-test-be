class Api::V1::PurchasesController < ApplicationController
  before_action :authenticate_request
  before_action :authenticate_customer!, only: [:create]
  skip_before_action :verify_authenticity_token

  def index
    # Extract pagination parameters
    page = params[:page].present? ? params[:page].to_i : 1
    limit = params[:limit].present? ? params[:limit].to_i : 10
    
    # Ensure valid values
    page = 1 if page < 1
    limit = 10 if limit < 1 || limit > 100  # Setting a max limit of 100
    
    # Calculate offset
    offset = (page - 1) * limit

    # Get appropriate purchases based on role
    if @current_user&.role == 'admin'
      purchases_query = Purchase.includes(:asset, :customer)
    elsif @current_user&.role == 'creator'
      assets = Asset.where(creator_id: @current_user.id)
      purchases_query = Purchase.includes(:asset, :customer).where(asset_id: assets.pluck(:id))
    else # customer
      purchases_query = Purchase.includes(:asset, :customer).where(customer_id: @current_user.id)
    end
    
    # Apply pagination after determining the base query
    total_count = purchases_query.count
    purchases = purchases_query.offset(offset).limit(limit)

    # Format the response data
    purchase_data = purchases.map { |purchase|
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
    }

    # Return the response data with pagination metadata
    render json: {
      purchases: purchase_data,
      meta: {
        current_page: page,
        per_page: limit,
        total_count: total_count,
        total_pages: (total_count.to_f / limit).ceil
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