module GeocodingProviders
  class OpenWeatherMap < Base
    BASE_URL = "http://api.openweathermap.org/geo/1.0/"

    def geocode(query)
      response = api_client.get("direct", {
        q: query,
        limit: 1
      })

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
