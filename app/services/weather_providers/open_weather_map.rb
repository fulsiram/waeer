module WeatherProviders
  class OpenWeatherMap < Base
    BASE_URL = "https://api.openweathermap.org/data/2.5/"

    def get_weather(location)
      raise ArgumentError, "location must be LocationData" unless location.is_a?(LocationData)

      response = api_client.get("weather", {
        lat: location.latitude,
        lon: location.longtitude,
        units: "metric"
      })

      if response.status == 400
        raise BadLocationError
      end

      WeatherMappers::OpenWeatherMap.map_current_weather(response.body)
    end

    def get_weather_forecast(location)
      raise ArgumentError, "location must be LocationData" unless location.is_a?(LocationData)

      response = api_client.get("forecast", {
        lat: location.latitude,
        lon: location.longtitude,
        units: "metric"
      })

      if response.status == 400
        raise BadLocationError
      end

      WeatherMappers::OpenWeatherMap.map_forecast_weather(response.body)
    end

    private
    def api_client
      token = ENV["OPENWEATHERMAP_TOKEN"]

      Faraday.new(
        url: BASE_URL,
        params: {
          appid: token
        }
      ) do |builder|
        builder.response :json
        builder.response :logger, nil, { bodies: true, headers: false, errors: true } do |logger|
          logger.filter(/(appid=)[^&]+/, '\1[FILTERED]')
        end
      end
    end
  end
end
