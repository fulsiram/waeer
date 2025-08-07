module GeocodingProviders
  class OpenWeatherMap < Base
    BASE_URL = "http://api.openweathermap.org/geo/1.0/"

    def geocode(query)
      response = api_client.get("direct", {
        q: query,
        limit: 1
      })

      unless response.success?
        Rails.logger.error("Geocoding error: query=#{query} response_code=#{response.status} response_body=#{response.body.to_json}")
        raise RequestError, response.status
      end

      data = response.body

      if data.empty?
        raise LocationNotFoundError
      end

      location = data.first

      LocationData.new(
        longitude: location["lon"],
        latitude: location["lat"],
        name: location["name"]
      )
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
