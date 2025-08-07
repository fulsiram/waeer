module GeocodingProviders
  class LocationNotFoundError < StandardError; end
  class RequestError < StandardError; end

  class Base
    def geocode(query)
      raise NotImplementedError
    end
  end
end
