module WeatherProviders
  class OpenWeatherMap < Base
    BASE_URL = "https://api.openweathermap.org/data/2.5/"

    def get_current_weather(location)
      raise ArgumentError, "location must be LocationData" unless location.is_a?(LocationData)

      response = api_client.get("weather", {
        lat: location.latitude,
        lon: location.longitude,
        units: "metric"
      })

      unless response.success?
        Rails.logger.error("Error fetching current weather: lat=#{location.latitude} lon=#{location.longitude} status=#{response.status} response_body=#{response.body.to_json}")

        if response.status == 400
          raise BadLocationError
        else
          raise RequestError, response.status
        end
      end

      DataMappers::OpenWeatherMap.map_current_weather(response.body)
    end

    def get_weather_forecast(location)
      raise ArgumentError, "location must be LocationData" unless location.is_a?(LocationData)

      response = api_client.get("forecast", {
        lat: location.latitude,
        lon: location.longitude,
        units: "metric"
      })

      unless response.success?
        Rails.logger.error("Error fetching weather forecast: lat=#{location.latitude} lon=#{location.longitude} status=#{response.status} response_body=#{response.body.to_json}")

        if response.status == 400
          raise BadLocationError
        else
          raise RequestError, response.status
        end
      end

      DataMappers::OpenWeatherMap.map_forecast_weather(response.body)
    end

    private
    def api_client
      Faraday.new(
        url: BASE_URL,
        params: {
          appid: api_token
        }
      ) do |builder|
        builder.response :json
        builder.response :logger, nil, { bodies: true, headers: false, errors: true } do |logger|
          logger.filter(/(appid=)[^&]+/, '\1[FILTERED]')
        end
      end
    end

    def api_token
      ENV.fetch("OPENWEATHERMAP_TOKEN") do
        raise "OPENWEATHERMAP_TOKEN environment variable is required"
      end
    end
  end
end
