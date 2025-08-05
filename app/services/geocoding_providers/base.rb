module GeocodingProviders
  class Base
    class LocationNotFoundError < Exception; end

    def geocode(query)
      raise NotImplementedError
    end
  end
end
