module GeocodingProviders
  class LocationNotFoundError < Exception; end

  class Base
    def geocode(query)
      raise NotImplementedError
    end
  end
end
