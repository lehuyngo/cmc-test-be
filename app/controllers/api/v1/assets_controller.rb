class Api::V1::AssetsController < ApplicationController
  before_action :authenticate_request
  before_action :authenticate_creator!, only: [:create, :bulk_import]
  skip_before_action :verify_authenticity_token

  def index
    page = params[:page].present? ? params[:page].to_i : 1
    limit = params[:limit].present? ? params[:limit].to_i : 10
    
    service = AssetService.new(@current_user)
    result = service.list_assets(page: page, limit: limit)
    
    render json: result
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
      
      # Use service for bulk import
      service = AssetService.new(@current_user)
      result = service.bulk_import(json_data)
      
      # Return appropriate response
      if result[:errors].empty?
        render json: { message: "Successfully imported #{result[:success_count]} assets." }, status: :ok
      else
        render json: { 
          message: "Imported #{result[:success_count]} assets with #{result[:errors].size} errors.",
          errors: result[:errors]
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