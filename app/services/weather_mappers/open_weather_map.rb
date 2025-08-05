module WeatherMappers
  class OpenWeatherMap
    def self.map_current_weather(api_response)
      CurrentWeather.new(
        temperature: api_response.dig("main", "temp"),
        condition: map_weather_condition(api_response.dig("weather", 0, "main")),
        pressure: api_response.dig("main", "pressure"),
        humidity: api_response.dig("main", "humidity")
      )
    end

    private

    def self.map_weather_condition(openweather_condition)
      case openweather_condition&.downcase
      when "clear"
        :clear_sky
      when "clouds"
        :few_clouds
      when "rain"
        :rain
      when "drizzle"
        :shower_rain
      when "thunderstorm"
        :thunderstorm
      when "snow"
        :snow
      when "mist", "smoke", "haze", "dust", "fog", "sand", "ash", "squall", "tornado"
        :mist
      else
        :clear_sky
      end
    end
  end
end
