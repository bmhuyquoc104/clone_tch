# frozen_string_literal: true

class ProductsController < ApplicationController
  PRICE_ORDER = %w[asc desc].freeze

  schema(:index) do
    required(:category_id).value(:uuid_v4?)
    optional(:price).value(included_in?: PRICE_ORDER)
  end

  def index
    service = GetProductsService.call(safe_params)

    if service.success?
      render json: { data: service.result }, status: :ok, each_serializer: ProductSerializer
    else
      render json: { message: service.first_error.message }, status: :unprocessable_entity
    end
  end

  schema(:show) do
    required(:id).value(:string, :uuid_v4?)
  end

  def show
    service = GetProductService.call(params[:id])

    if service.success?
      # TODO: Use custom serializer to accept more generic case
      product = service.result
      product = ProductSerializer.new(product).serializable_hash if product.is_a? Product
      render json: { data: product }, status: :ok

    else
      render json: { message: service.first_error.message }, status: :unprocessable_entity
    end
  end

  def above_average_price
    # products = Product.where('price > (SELECT AVG(price) FROM products)')
    products = Product.where('price > (:avg)', avg: Product.minimum(:price))

    render json: products, status: :ok
  end

  schema(:update) do
    required(:id).value(:uuid_v4?)
    optional(:name).filled(:string)
    optional(:description).filled(:string)
    optional(:price).filled(:float).value(gt?: 0)
    optional(:image_urls).filled(array[:string])
  end

  def update
    @product = Product.update!(safe_params[:id], safe_params.to_h)

    render json: { data: @product }, status: :ok
  end

  schema(:destroy) do
    required(:id).value(:uuid_v4?)
  end

  def destroy
    @product = Product.destroy(safe_params[:id])

    render status: :no_content
  end
end
