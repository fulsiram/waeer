module WeatherHelper
  WEATHER_ICON_MAPPING = {
    "clear_sky" => "sun",
    "few_clouds" => "cloud-sun",
    "scattered_clouds" => "cloud",
    "broken_clouds" => "clouds",
    "shower_rain" => "cloud-drizzle",
    "rain" => "cloud-rain",
    "thunderstorm" => "zap",
    "snow" => "snowflake",
    "mist" => "cloud-fog"
  }.freeze

  WEATHER_ICON_COLOR_MAPPING = {
    "clear_sky" => "text-yellow-500",
    "few_clouds" => "text-gray-400",
    "scattered_clouds" => "text-gray-500",
    "broken_clouds" => "text-gray-600",
    "shower_rain" => "text-blue-400",
    "rain" => "text-blue-500",
    "thunderstorm" => "text-purple-500",
    "snow" => "text-blue-200",
    "mist" => "text-gray-400"
  }.freeze

  def get_weather_icon(condition)
    return "cloud-sun" if condition.blank?

    WEATHER_ICON_MAPPING[condition.to_s] || "cloud-sun"
  end

  def get_weather_icon_color(condition)
    return "text-gray-400" if condition.blank?

    WEATHER_ICON_COLOR_MAPPING[condition.to_s] || "text-gray-400"
  end

  def format_wind_speed(speed_kmh)
    return "0 km/h" if speed_kmh.nil? || speed_kmh.zero?

    "#{speed_kmh.round} km/h"
  end

  def format_wind_direction(degrees)
    return "" if degrees.nil?

    directions = %w[N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW]
    index = ((degrees + 11.25) / 22.5).to_i % 16
    directions[index]
  end

  def format_wind(speed_kmh, direction_degrees)
    speed_text = format_wind_speed(speed_kmh)
    return speed_text if direction_degrees.nil?

    direction_text = format_wind_direction(direction_degrees)
    "#{speed_text} #{direction_text}"
  end

  def format_temperature(temperature)
    return "--°" if temperature.nil?

    "#{temperature.round}°"
  end

  def format_pressure(pressure)
    return "--" if pressure.nil?

    "#{pressure} hPa"
  end

  def format_humidity(humidity)
    return "--%" if humidity.nil?

    "#{humidity}%"
  end

  def temperature_bar_width(current_min, current_max, forecast)
    return 100 if forecast.nil? || forecast.empty?

    day_ranges = forecast.map { |day| day.max_temperature - day.min_temperature }.compact

    return 100 if day_ranges.empty?

    max_range = day_ranges.max
    current_range = current_max - current_min

    return 100 if max_range == 0

    percentage = (current_range / max_range * 100).round
    [ percentage, 40 ].max
  end
end
