class CurrentWeather
  include ActiveModel::Model
  include ActiveModel::Attributes
  include WeatherConditions

  attribute :temperature, :float
  attribute :pressure, :integer
  attribute :humidity, :integer
end
