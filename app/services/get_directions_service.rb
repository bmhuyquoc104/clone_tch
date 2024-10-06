# frozen_string_literal: true

class GetDirectionsService < BaseService
  DEFAULT_TRANSPORTATION = 'driving'

  TRANSPORTATION_WHITE_LIST = %w[driving cycling walking].freeze

  def initialize(store_id:, transportation:, user_coordinates:)
    super()
    @transportation = transportation || DEFAULT_TRANSPORTATION
    @store_id = store_id
    @user_coordinates = user_coordinates
  end

  def call
    validate!
    return self if error?

    fetch_request
  end

  private

  def fetch_request
    get_direction_request = Mapbox::GetDirectionsRequest.call(user_coordinates: @user_coordinates, store_coordinates:,
                                                              transportation: @transportation)
    puts "test len file moi"

    if get_direction_request.error?
      add_error(get_direction_request.first_error)
    else
      @result = get_direction_request.response
    end
  end

  def validate!
    return add_error(I18n.t('errors.models.not_supported', record: :transportation)) if invalid_transportation

    return add_error(I18n.t('errors.models.not_found', record: :store)) if store.blank?

    add_error(I18n.t('errors.models.not_found', record: 'address of store')) if store.address.blank?
  end

  def invalid_transportation
    TRANSPORTATION_WHITE_LIST.exclude?(@transportation)
  end

  def store
    return @store if defined? @store

    @store = Store.includes(:address).find_by(id: @store_id)
  end

  def store_coordinates
    [@store.address.longitude, @store.address.latitude]
  end
end
