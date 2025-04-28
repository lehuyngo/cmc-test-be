class Asset < ApplicationRecord
    belongs_to :creator, class_name: "User", foreign_key: "creator_id"
    has_many :purchases
    has_many :customers, through: :purchases

    validates :title, presence: true
    validates :description, presence: true
    validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :file_url, presence: true

    def purchased_by?(user)
        customers.include?(user)
    end
end