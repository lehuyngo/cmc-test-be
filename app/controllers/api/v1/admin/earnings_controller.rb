class Api::V1::Admin::EarningsController < ApplicationController
    before_action :authenticate_admin!

    def index
    @creators = User.joins(:created_assets)
                    .where(role: 'creator')
                    .select('users.*, SUM(purchases.amount) as total_earnings')
                    .joins('LEFT JOIN purchases ON purchases.asset_id = assets.id')
                    .group('users.id')
                    
    render json: @creators.map { |creator| 
      {
        creator_id: creator.id,
        creator_name: creator.name,
        total_earnings: creator.total_earnings || 0
      }
    }
  end

end
