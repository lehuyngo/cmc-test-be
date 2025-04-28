class Api::V1::AssetsController < ApplicationController
  before_action :authenticate_request
  before_action :authenticate_creator!, only: [:create, :bulk_import]
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

    # Get appropriate assets based on role with pagination
    if @current_user&.role == 'creator'
      assets_query = Asset.where(creator_id: @current_user.id)
    else 
      assets_query = Asset.all
    end
    
    # Apply pagination
    total_count = assets_query.count
    assets = assets_query.offset(offset).limit(limit)

    # Prepare the response data
    asset_data = assets.map do |asset|
      asset_json = asset.as_json
      
      # Add purchase status for customers
      if @current_user&.role == 'customer'
        is_purchased = Purchase.where(
          customer_id: @current_user.id, 
          asset_id: asset.id
        ).exists?
        
        asset_json['is_purchased'] = is_purchased
        
        # If the asset is not purchased, set file_url to null
        unless is_purchased
          asset_json['file_url'] = nil
        end
      end
      
      asset_json
    end

    # Return the response data with pagination metadata
    render json: {
      assets: asset_data,
      meta: {
        current_page: page,
        per_page: limit,
        total_count: total_count,
        total_pages: (total_count.to_f / limit).ceil
      }
    }
  end

  def create
    @asset = current_user.created_assets.build(asset_params)

    if @asset.save
      redirect_to @asset, notice: "Asset was successfully created."
    else
      render :new
    end
  end

  def bulk_import
    # Check if file exists
    if params[:json_file].nil?
      render json: { error: "No file uploaded" }, status: :unprocessable_entity
      return
    end

    begin
      # Parse JSON data
      json_data = JSON.parse(params[:json_file].read)
      
      # Validate JSON format
      unless json_data.is_a?(Array)
        render json: { error: "Invalid JSON format. Expected an array of assets." }, status: :unprocessable_entity
        return
      end
      
      # Initialize counters
      success_count = 0
      errors = []
      
      # Process each asset
      json_data.each do |asset_data|
        # Validate required fields
        if asset_data["title"].blank? || asset_data["description"].blank? || asset_data["file_url"].blank?
          errors << "Missing required fields for asset."
          next
        end
        
        # Build asset object
        asset = Asset.new(
          title: asset_data["title"],
          description: asset_data["description"],
          file_url: asset_data["file_url"],
          price: asset_data["price"],
          creator_id: @current_user.id
        )
        
        # Save asset
        if asset.save
          success_count += 1
        else
          errors << "Error saving asset: #{asset_data['title']}: #{asset.errors.full_messages.join(', ')}"
        end
      end
      
      # Return appropriate response
      if errors.empty?
        render json: { message: "Successfully imported #{success_count} assets." }, status: :ok
      else
        render json: { 
          message: "Imported #{success_count} assets with #{errors.size} errors.",
          errors: errors 
        }, status: :unprocessable_entity
      end
      
    rescue JSON::ParserError
      render json: { error: "Invalid JSON format" }, status: :unprocessable_entity
    rescue => e
      # Catch any other errors
      render json: { error: "An error occurred: #{e.message}" }, status: :unprocessable_entity
    end
  end
  
  private
  
  def asset_params
    params.require(:asset).permit(:title, :description, :file_url, :price)
  end
end