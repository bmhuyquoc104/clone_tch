# frozen_string_literal: true

require 'rails_helper'

describe GetProductsService do
  subject(:service) { described_class.new(category_id) }

  let(:all_category) { create(:category, name: 'all') }
  let(:tea_category) { create(:category, parent: all_category, name: 'Tea category') }
  let(:coffee_category) { create(:category, parent: all_category, name: 'Coffee category') }
  let(:milk_tea_category) { create(:category, parent: tea_category, name: 'Milk Tea category') }
  let(:hi_tea_category) { create(:category, parent: tea_category, name: 'Hi Tea category') }

  let!(:americano) { create(:product, category: coffee_category, name: 'Americano') }
  let!(:iced_coffee) { create(:product, category: coffee_category, name: 'Iced Coffee') }
  let!(:hi_tea) { create(:product, category: hi_tea_category, name: 'Hi Tea') }
  let!(:milk_tea) { create(:product, category: milk_tea_category, name: 'Milk Tea') }

  describe '#validate' do
    context 'when category_id does not exist in db' do
      let(:category_id) { SecureRandom.uuid }

      before do
        allow(CacheManager).to receive(:fetch_value).and_return(nil)
      end

      it 'returns error' do
        service.call

        expect(service.error?).to eq true
        expect(service.first_error.message).to eq 'category is not found.'
      end
    end

    describe '#call' do
      let(:expected_hi_tea) do
        {
          id: hi_tea.id,
          name: hi_tea.name,
          price: hi_tea.price,
          thumbnail: hi_tea.thumbnail,
          tag: {
            color: nil,
            name: nil
          }
        }
      end

      let(:expected_iced_coffee) do
        {
          id: iced_coffee.id,
          name: iced_coffee.name,
          price: iced_coffee.price,
          thumbnail: iced_coffee.thumbnail,
          tag: {
            color: nil,
            name: nil
          }
        }
      end

      let(:expected_americano) do
        {
          id: americano.id,
          name: americano.name,
          price: americano.price,
          thumbnail: americano.thumbnail,
          tag: {
            color: nil,
            name: nil
          }
        }
      end

      let(:expected_milk_tea) do
        {
          id: milk_tea.id,
          name: milk_tea.name,
          price: milk_tea.price,
          thumbnail: milk_tea.thumbnail,
          tag: {
            color: nil,
            name: nil
          }
        }
      end

      context 'when products within category exists in cache' do
        before do
          allow(CacheManager).to receive(:fetch_value).and_return(expected_result.to_json)
        end

        context 'when a category does not have a parent category' do
          let(:category_id) { all_category.id }
          let(:expected_result) do
            [
              {
                name: 'Coffee category',
                products: match_array([expected_iced_coffee, expected_americano])
              },
              {
                name: 'Milk Tea category',
                products: [expected_milk_tea]
              },
              {
                name: 'Hi Tea category',
                products: [expected_hi_tea]
              }
            ]
          end

          it 'returns categories having products' do
            service.call

            expect(service.success?).to eq true
            expect(service.result.size).to eq 3
            expect(service.result.to_json).to eq(expected_result.to_json)
          end
        end

        context 'when a category has a parent category' do
          context 'when a category has children categories' do
            let(:category_id) { tea_category.id }
            let(:expected_result) do
              [
                {
                  name: 'Hi Tea category',
                  products: [expected_hi_tea]
                },
                {
                  name: 'Milk Tea category',
                  products: [expected_milk_tea]
                }
              ]
            end

            it 'returns children categories having products' do
              service.call

              expect(service.success?).to eq true
              expect(service.result.size).to eq 2
              expect(service.result.to_json).to eq(expected_result.to_json)
            end
          end

          context 'when a category does not have children categories' do
            let(:category_id) { milk_tea_category.id }
            let(:expected_result) do
              [
                {
                  name: 'Milk Tea category',
                  products: [expected_milk_tea]
                }
              ]
            end

            it 'returns that category having products' do
              service.call

              expect(service.success?).to eq true
              expect(service.result.size).to eq 1
              expect(service.result.to_json).to eq(expected_result.to_json)
            end
          end
        end
      end

      context 'when products within category does not exist in cache' do
        include_context 'redis mock'

        let(:cached_value) do
          JSON.parse(redis.get(category_id)).map do |category|
            {
              name: category['name'],
              products: category['products'].map do |product|
                {
                  id: product['id'],
                  name: product['name'],
                  price: product['price'].to_f,
                  thumbnail: product['thumbnail'],
                  tag: {
                    color: product['tag']['color'],
                    name: product['tag']['name']
                  }
                }
              end
            }
          end
        end

        before do
          allow(CacheManager).to receive(:fetch_value).and_return(nil)
        end

        context 'when a category does not have a parent category' do
          let(:category_id) { all_category.id }
          let(:expected_result) do
            [
              {
                name: 'Coffee category',
                products: match_array([expected_iced_coffee, expected_americano])
              },
              {
                name: 'Milk Tea category',
                products: [expected_milk_tea]
              },
              {
                name: 'Hi Tea category',
                products: [expected_hi_tea]
              }
            ]
          end

          it 'returns categories having products' do
            service.call

            expect(service.success?).to eq true
            expect(service.result.size).to eq 3
            expect(service.result).to match_array(expected_result)
            expect(cached_value).to match_array(expected_result)
          end
        end

        context 'when a category has a parent category' do
          context 'when a category has children categories' do
            let(:category_id) { tea_category.id }
            let(:expected_result) do
              [
                {
                  name: 'Hi Tea category',
                  products: [expected_hi_tea]
                },
                {
                  name: 'Milk Tea category',
                  products: [expected_milk_tea]
                }
              ]
            end

            it 'returns children categories having products' do
              service.call

              expect(service.success?).to eq true
              expect(service.result.size).to eq 2
              expect(service.result).to match_array(expected_result)
              expect(cached_value).to eq(expected_result)
            end
          end

          context 'when a category does not have children categories' do
            let(:category_id) { milk_tea_category.id }
            let(:expected_result) do
              [
                {
                  name: 'Milk Tea category',
                  products: [expected_milk_tea]
                }
              ]
            end

            it 'returns that category having products' do
              service.call

              expect(service.success?).to eq true
              expect(service.result.size).to eq 1
              expect(service.result).to eq(expected_result)
              expect(cached_value).to eq(expected_result)
            end
          end
        end
      end
    end
  end
end
