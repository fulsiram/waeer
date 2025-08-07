class CurrentWeather
  include ActiveModel::Model
  include ActiveModel::Attributes
  include WeatherConditions

  attribute :temperature, :float
  attribute :pressure, :integer
  attribute :humidity, :integer
  attribute :wind_speed, :float
  attribute :wind_direction, :integer
end
