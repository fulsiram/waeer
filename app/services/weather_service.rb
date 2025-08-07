class WeatherService
  def initialize(
    weather_provider: WeatherProviders::OpenWeatherMap.new,
    geocoding_provider: GeocodingProviders::OpenWeatherMap.new
  )
    @weather_provider = weather_provider
    @geocoding_provider = geocoding_provider
  end

  def get_weather_for_query(query)
    raise ArgumentError("query is empty") if query.blank?

    cache_key = "geocoding:#{query.downcase.strip}"
    location = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      @geocoding_provider.geocode(query)
    end

    cache_key = "weather:#{location.latitude}:#{location.longitude}"
    from_cache = Rails.cache.exist?(cache_key)

    weather_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      get_weather_data(location)
    end

    weather_data.from_cache = from_cache

    weather_data
  end

  def get_weather_data(location)
    current_weather = @weather_provider.get_current_weather(location)
    forecast_weather = @weather_provider.get_weather_forecast(location)

    WeatherData.new(
      location: location,
      current: current_weather,
      forecast: forecast_weather,
      updated_at: Time.current
    )
  end
end
