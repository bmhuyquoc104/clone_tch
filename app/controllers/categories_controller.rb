# frozen_string_literal: true

class CategoriesController < ApplicationController
  schema(:sizes) do
    required(:id).value(:uuid_v4?)
  end

  def sizes
    service = GetSizesService.call(safe_params)

    render json: { data: service.result }, status: :ok
  end

  schema(:toppings) do
    required(:id).value(:uuid_v4?)
  end

  def toppings
    service = GetToppingsService.call(safe_params)

    render json: { data: service.result }, status: :ok
  end
end
