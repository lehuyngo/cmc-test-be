require "jwt"
module JsonWebToken
    extend ActiveSupport::Concern
    JWT_SECRET = ENV.fetch("JWT_SECRET")

    def self.jwt_encode(payload)
        payload[:exp] = 24.hours.from_now.to_i
        JWT.encode(payload, JWT_SECRET)
    end

    def self.jwt_decode(token)
        body = JWT.decode(token, JWT_SECRET)[0]
        HashWithIndifferentAccess.new body
    rescue
        nil
    end
end
