# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  let(:tea_category) { create(:category) }
  let(:tea) { create(:product, category: tea_category) }

  describe 'GET #sizes' do
    context 'when category id is invalid' do
      it 'returns 400 response' do
        get :sizes, params: { id: 'invalid-uuid-format' }

        expect(response.status).to eq 400
        expect(response.parsed_body).to eq('errors' => 'id is not a valid UUID')
      end
    end

    context 'when category id is valid' do
      let!(:small) { create(:size, product: tea) }
      it 'returns 200 response' do
        get :sizes, params: { id: tea_category.id }

        expect(response.status).to eq 200
        expect(response.parsed_body[:data].first[:id]).to eq(small.id)
      end
    end
  end

  describe 'GET #toppings' do
    context 'when category id is invalid' do
      it 'returns expected response' do
        get :toppings, params: { id: 'invalid-uuid-format' }

        expect(response.status).to eq 400
        expect(response.parsed_body).to eq('errors' => 'id is not a valid UUID')
      end
    end

    context 'when category id is valid' do
      let!(:jelly) { create(:topping, product: tea) }
      it 'returns 200 response' do
        get :toppings, params: { id: tea_category.id }

        expect(response.status).to eq 200
        expect(response.parsed_body[:data].first[:id]).to eq(jelly.id)
      end
    end
  end
end
