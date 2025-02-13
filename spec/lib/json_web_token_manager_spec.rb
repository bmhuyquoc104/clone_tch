require 'rails_helper'

RSpec.describe JsonWebTokenManager do
  let(:mocked_token) { 'mocked_token' }
  let(:secret_key) { Rails.application.credentials.secret_key_base }
  let(:user_id) { 123 }

  describe '#encode' do
    before do
      allow(JWT).to receive(:encode).and_return(:mocked_token)
    end

    it 'returns a valid token' do
      token = JsonWebTokenManager.encode(user_id)
      expect(token).to eq(:mocked_token)
    end
  end

  describe '#decode' do
    let(:decoded_token) { { user_id: user_id, 'exp' => 10.minutes.from_now.to_i } }

    before do
      allow(JWT).to receive(:decode).and_return([decoded_token])
    end

    it 'returns the payload' do
      result = JsonWebTokenManager.decode(mocked_token)
      expect(result).to eq(decoded_token)
    end

    it 'raises an error when decoding fails' do
      allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)
      expect { JsonWebTokenManager.decode(mocked_token) }.to raise_error(JWT::DecodeError)
    end
  end
end
