class ForecastWeather
  include ActiveModel::Model
  include ActiveModel::Attributes
  include WeatherConditions

  attribute :date, :date
  attribute :min_temperature, :float
  attribute :max_temperature, :float
  attribute :pressure, :integer
  attribute :humidity, :integer
end
