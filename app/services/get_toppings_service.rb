# frozen_string_literal: true

class GetToppingsService < BaseService
  def initialize(safe_params)
    super()
    @category_id = safe_params[:id]
  end

  def call
    if Category.where(id: safe_params[:id], parent_id: nil).present?
      @result = Topping.select('toppings.id AS id, toppings.name AS name')
    else
      @result = Category.joins(products: :toppings)
                         .where(id: safe_params[:id])
                         .select('toppings.id AS id, toppings.name AS name')
    end
  end
end
