# frozen_string_literal: true

class FacilitiesController < ApplicationController
  schema(:show) do
    required(:id).value(:uuid_v4?)
  end

  def show
    facility = Facility.find(safe_params[:id])

    render json: facility, status: :ok
  end

  schema(:create) do
    required(:store_id).value(:integer)
    required(:name).filled(:string)
    required(:icon).filled(:string)
  end

  def create
    store = Store.find(safe_params[:store_id])
    facility = store.facilities.create!(
      name: safe_params[:name],
      icon: safe_params[:icon]
    )

    render json: facility, status: :created
  end

  schema(:update) do
    required(:id).value(:uuid_v4?)
    optional(:name).filled(:string)
    optional(:icon).filled(:string)
  end

  def update
    facility = Facility.update!(safe_params[:id], name: safe_params[:name], icon: safe_params[:icon])

    render json: facility, status: :accepted
  end

  schema(:destroy) do
    required(:id).value(:uuid_v4?)
  end

  def destroy
    Facility.destroy_by(id: safe_params[:id])

    render status: :no_content
  end
end
