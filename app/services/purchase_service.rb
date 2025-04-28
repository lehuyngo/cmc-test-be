# app/services/purchase_service.rb
class PurchaseService
    def initialize(current_user)
      @current_user = current_user
    end
  
    def list_purchases(page: 1, limit: 10)
      # Validate pagination params
      page = 1 if page < 1
      limit = 10 if limit < 1 || limit > 100
      
      # Get base query depending on user role
      purchases_query = get_purchases_query
      
      # Apply pagination
      total_count = purchases_query.count
      purchases = purchases_query.offset((page - 1) * limit).limit(limit)
      
      # Format purchase data
      purchase_data = format_purchases(purchases)
      
      # Return data with pagination metadata
      {
        purchases: purchase_data,
        meta: {
          current_page: page,
          per_page: limit,
          total_count: total_count,
          total_pages: (total_count.to_f / limit).ceil
        }
      }
    end
    
    def create_purchase(asset_id)
      asset = Asset.find(asset_id)
      purchase = Purchase.new(customer_id: @current_user.id, asset_id: asset.id)
      
      if purchase.save
        { success: true, purchase: purchase }
      else
        { success: false, errors: purchase.errors.full_messages }
      end
    end
  
    private
    
    def get_purchases_query
      if @current_user&.role == 'admin'
        Purchase.includes(:asset, :customer)
      elsif @current_user&.role == 'creator'
        assets = Asset.where(creator_id: @current_user.id)
        Purchase.includes(:asset, :customer).where(asset_id: assets.pluck(:id))
      else # customer
        Purchase.includes(:asset, :customer).where(customer_id: @current_user.id)
      end
    end
    
    def format_purchases(purchases)
      purchases.map { |purchase|
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
    end
  end