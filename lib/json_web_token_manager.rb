# frozen_string_literal: true

class JsonWebTokenManager
  def self.encode(user_id)
    payload = {
      user_id: user_id,
      exp: 10.minutes.from_now.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def self.decode(token)
    JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithms: 'HS256').first
  end
end
