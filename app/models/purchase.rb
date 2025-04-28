class Purchase < ApplicationRecord
  belongs_to :customer, class_name: 'User'
  belongs_to :asset
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  
  before_validation :set_amount
  
  private
  
  def set_amount
    self.amount ||= asset.price if asset
  end
end