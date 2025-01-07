# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  let(:tea_category) { create(:category) }
  let!(:tea) { create(:product, category: tea_category) }

  describe 'GET #index' do
    context 'when category_id is invalid' do
      it 'returns expected response' do
        get :index, params: { category_id: 'invalid-uuid-format' }

        expect(response.status).to eq 400
        expect(response.parsed_body).to eq('errors' => 'category_id is not a valid UUID')
      end
    end

    context 'when category_id is valid' do
      let(:service_result) { instance_double(GetProductService, success?: true, result: tea) }

      before do
        allow(GetProductsService).to receive(:call).with(tea_category.id).and_return(service_result)
      end

      it 'renders products successfully' do
        get :index, params: { category_id: tea_category.id }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #show' do
    context 'when product_id is invalid' do
      it 'returns expected response' do
        get :show, params: { id: 'invalid-uuid-format' }

        expect(response.status).to eq 400
        expect(response.parsed_body).to eq('errors' => 'id is not a valid UUID')
      end
    end

    context 'when product_id is valid' do
      context 'when request call is successful' do
        let(:service_result) { instance_double(GetProductService, success?: true, result: tea) }

        before do
          allow(GetProductService).to receive(:call).with(tea.id).and_return(service_result)
        end

        it 'renders the product successfully' do
          get :show, params: { id: tea.id }

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body['data']).to be_present
        end
      end

      context 'when request call fails' do
        let(:random_id) { SecureRandom.uuid }
        let(:service_failure) do
          instance_double(GetProductService, success?: false, first_error: StandardError.new('product not found'))
        end

        before do
          allow(GetProductService).to receive(:call).with(random_id).and_return(service_failure)
        end

        it 'renders an error message' do
          get :show, params: { id: random_id }

          expect(response.status).to eq 422
          expect(response.parsed_body).to eq({ 'message' => 'product not found' })
        end
      end
    end
  end

  describe 'PUT #update' do
    context 'validation' do
      let(:request_param) do
        { id: 'invalid-id', name: '', price: -2 }
      end

      context 'when validation fails' do
        it 'returns 400 response' do
          put :update, params: request_param

          expect(response.status).to eq 400
          expect(response.parsed_body).to eq(
            'errors' => 'id is not a valid UUID, name must be filled, price must be greater than 0'
          )
        end
      end
    end

    context 'when product does not exist in database' do
      let(:id) { SecureRandom.uuid }
      let(:request_param) { { id: } }

      it 'returns 404 response' do
        put :update, params: request_param

        expect(response.status).to eq 404
        expect(response.parsed_body).to eq('errors' => "Couldn't find Product with 'id'=#{id}")
      end
    end

    context 'when name is duplicated' do
      let(:request_param) do
        { id: tea.id, name: milk_tea.name }
      end

      let(:milk_tea) { create(:product, category: tea_category) }

      it 'returns 422 response' do
        put :update, params: request_param

        expect(response.status).to eq 422
        expect(response.parsed_body).to eq('message' => 'Validation failed: Name has already been taken')
      end
    end

    context 'when body is valid' do
      let(:request_param) do
        { id: tea.id, name: 'Milk tea' }
      end

      let(:expected_body) do
        {
          'name' => 'Milk tea',
          'thumbnail' => 'MyString',
          'description' => 'MyString',
          'image_urls' => [],
          'price' => '9.99'
        }
      end

      before do
        allow(CacheManager).to receive(:unassign_value).with(tea.id)
        allow(CacheManager).to receive(:assign_value)
      end

      it 'returns 200 response' do
        put :update, params: request_param

        expect(response.status).to eq 200
        expect(response.parsed_body['data']).to include(expected_body)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when product_id is invalid' do
      it 'returns 400 response' do
        delete :destroy, params: { id: 'invalid-uuid-format' }

        expect(response.status).to eq 400
        expect(response.parsed_body).to eq('errors' => 'id is not a valid UUID')
      end
    end

    context 'when product_id is valid' do
      context 'when product exists in database' do
        before do
          allow(CacheManager).to receive(:unassign_value).with(tea.id)
        end

        it 'returns 204 response' do
          delete :destroy, params: { id: tea.id }

          expect(response.status).to eq 204
          expect(Product.find_by(id: tea.id)).to eq nil
        end
      end

      context 'when product does not exist in database' do
        let(:id) { SecureRandom.uuid }
        it 'returns 404 response' do
          delete :destroy, params: { id: }

          expect(response.status).to eq 404
          expect(response.parsed_body).to eq('errors' => "Couldn't find Product with 'id'=#{id}")
        end
      end
    end
  end
end
