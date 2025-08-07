class WeatherController < ApplicationController
  def index
    if params[:location].present?
      weather_service = WeatherService.new
      @weather_data = weather_service.get_weather_for_query(params[:location])
    end
  rescue GeocodingProviders::LocationNotFoundError
    flash.now[:alert] = "Location not found. Please try a different city name."
  rescue => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    flash.now[:alert] = "Something went wrong. Please try again later."
  end
end
