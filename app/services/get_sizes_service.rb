# frozen_string_literal: true

class GetSizesService < BaseService
  def initialize(safe_params)
    super()
    @category_id = safe_params[:id]
  end

  def call
    if Category.where(id: safe_params[:id], parent_id: nil).present?
      @result = Size.select('sizes.id AS id, sizes.name AS name')
    else
      @result = Category.joins(products: :sizes)
                      .where(id: safe_params[:id])
                      .select('sizes.id AS id, sizes.name AS name')
    end
  end
end
