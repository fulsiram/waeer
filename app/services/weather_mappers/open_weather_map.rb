module WeatherMappers
  class OpenWeatherMap
    def self.map_current_weather(api_response)
      CurrentWeather.new(
        temperature: api_response.dig("main", "temp"),
        condition: map_weather_condition(api_response.dig("weather", 0, "main")),
        pressure: api_response.dig("main", "pressure"),
        humidity: api_response.dig("main", "humidity"),
        wind_speed: api_response.dig("wind", "speed"),
        wind_direction: api_response.dig("wind", "deg")
      )
    end

    def self.map_forecast_weather(api_response)
      hourly_forecasts = api_response["list"].map do |forecast|
        {
          date: Date.parse(forecast["dt_txt"]),
          min_temperature: forecast.dig("main", "temp_min"),
          max_temperature: forecast.dig("main", "temp_max"),
          condition: map_weather_condition(forecast.dig("weather", 0, "main")),
          pressure: forecast.dig("main", "pressure"),
          humidity: forecast.dig("main", "humidity")
        }
      end

      # Aggregate hourly forecasts into daily summaries
      hourly_forecasts.group_by { |f| f[:date] }.map do |date, day_forecasts|
        ForecastWeather.new(
          date: date,
          min_temperature: day_forecasts.map { |f| f[:min_temperature] }.min,
          max_temperature: day_forecasts.map { |f| f[:max_temperature] }.max,
          condition: most_common_condition(day_forecasts.map { |f| f[:condition] }),
          pressure: (day_forecasts.sum { |f| f[:pressure] } / day_forecasts.size).round,
          humidity: (day_forecasts.sum { |f| f[:humidity] } / day_forecasts.size).round
        )
      end
    end

    private
    def self.most_common_condition(conditions)
      conditions.group_by(&:itself).max_by { |_, group| group.size }&.first || "clear_sky"
    end

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
      # Group various atmospheric conditions under 'mist' for simplicity
      when "mist", "smoke", "haze", "dust", "fog", "sand", "ash", "squall", "tornado"
        :mist
      else
        Rails.logger.warn("Unknown OpenWeatherMap condition: #{openweather_condition}")
        # Fallback to clear_sky to not break anything
        :clear_sky
      end
    end
  end
end
