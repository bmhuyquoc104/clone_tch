# frozen_string_literal: true

class StoresController < ApplicationController
  schema(:directions) do
    required(:id).filled(:integer)
    required(:address).value(:string)
    optional(:transportation).value(:string)
  end

  def directions
    coordinates = process_service(service_name: GetUserCoordinatesService, params: { address: safe_params[:address] })

    directions = process_service(service_name: GetDirectionsService,
                                 params: {
                                   store_id: safe_params[:id],
                                   transportation: safe_params[:transportation],
                                   user_coordinates: coordinates
                                 })

    render json: { data: directions }, status: :ok
  end

  schema(:index) do
    optional(:days)
      .array(:string)
      .each(included_in?: %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday])
  end

  def index
    stores = Store.includes(:stores_working_hours, :working_hours).where.not('stores_working_hours.day': nil)

    stores = stores.where('stores_working_hours.day': safe_params[:days]) if safe_params[:days].present?

    render json: stores
  end

  private

  def process_service(service_name:, params: {})
    service = service_name.call(**params)

    raise CustomErrors::UnprocessableService, service.first_error if service.error?

    service.result
  end
end
