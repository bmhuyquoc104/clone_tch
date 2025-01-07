# frozen_string_literal: true

class GetProductsService < BaseService
  def initialize(safe_params)
    super()
    @category_id = safe_params[:category_id]
    @price = safe_params[:price]
  end

  def call
    cached_products = CacheManager.fetch_value(category_id)
    if cached_products.present?
      @result = JSON.parse(cached_products)
    else
      validate
      return self if error?

      @result = fetch_products
      CacheManager.assign_value(category_id, @result.to_json)
    end
  end

  private

  attr_reader :category_id

  def build_products_cte
    if Category.where(id: @category_id, parent_id: nil).present?
      Product.with(products: Product.left_outer_joins(category: :parent))
    else
      Product.with(products: Product.left_outer_joins(category: :parent)
                                    .where(category_id: @category_id)
                                    .or(Category.where(parent_id: @category_id)))
    end
  end

  def build_query
    products = build_products_cte
    products = products.left_outer_joins(:tag)
                       .joins(:category)
                       .joins(category: :parent)
    products = product.order('products.price': @price) if @price.present?
    products.select('products.id AS product_id, products.name AS product_name,
                 products.price AS product_price, products.thumbnail AS product_thumbnail,
                 categories.id AS category_id, categories.name AS category_name,
    tags.name AS tag_name, tags.color AS tag_color')
  end

  def fetch_products
    products = build_query
    @result = products.group_by { |product| product[:category_name] }.map do |category_name, elements|
      {
        name: category_name,
        products: elements.map! do |element|
          transform_product(element)
        end
      }
    end
  end

  def transform_product(product)
    {
      id: product[:product_id],
      name: product[:product_name],
      price: product[:product_price],
      thumbnail: product[:product_thumbnail],
      tag: {
        name: product[:tag_name],
        color: product[:tag_color]
      }
    }
  end

  def validate
    add_error(I18n.t('errors.models.not_found', record: :category)) if Category.where(id: @category_id).blank?
  end
end
