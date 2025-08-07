module WeatherProviders
  class BadLocationError < StandardError; end
  class RequestError < StandardError; end

  class Base
    def get_current_weather(location)
      raise NotImplementedError
    end

    def get_weather_forecast(location)
      raise NotImplementedError
    end
  end
end
