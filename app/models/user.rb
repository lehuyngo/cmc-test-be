class User < ApplicationRecord
    has_secure_password
    has_many :created_assets, class_name: "Asset", foreign_key: "creator_id"
    has_many :purchases, foreign_key: "customer_id"
    has_many :purchased_assets, through: :purchases, source: :asset

    validates :name, presence: true
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true, length: { minimum: 6 }
    validates :role, inclusion: { in: [ "admin", "creator", "customer" ] }

    def admin?
        role == "admin"
    end
    def creator?
        role == "creator"
    end
    def customer?
        role == "customer"
    end
end
