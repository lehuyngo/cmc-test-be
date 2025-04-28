# app/services/asset_service.rb
class AssetService
    def initialize(current_user)
      @current_user = current_user
    end
  
    def list_assets(page: 1, limit: 10)
      # Validate pagination params
      page = 1 if page < 1
      limit = 10 if limit < 1 || limit > 100
      
      # Get base query depending on user role
      assets_query = get_assets_query
      
      # Apply pagination
      total_count = assets_query.count
      assets = assets_query.offset((page - 1) * limit).limit(limit)
      
      # Process assets for response
      asset_data = process_assets(assets)
      
      # Return data with pagination metadata
      {
        assets: asset_data,
        meta: {
          current_page: page,
          per_page: limit,
          total_count: total_count,
          total_pages: (total_count.to_f / limit).ceil
        }
      }
    end
    
    def bulk_import(json_data)
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
      
      # Return result summary
      {
        success_count: success_count,
        errors: errors
      }
    end
  
    private
    
    def get_assets_query
      if @current_user&.role == 'creator'
        Asset.where(creator_id: @current_user.id)
      else 
        Asset.all
      end
    end
    
    def process_assets(assets)
      assets.map do |asset|
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
    end
  end