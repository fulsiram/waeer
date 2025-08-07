class WeatherData
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :location
  attribute :current
  attribute :forecast
  attribute :updated_at, :datetime
  attribute :from_cache, :boolean
end
