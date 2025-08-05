module WeatherConditions
  extend ActiveSupport::Concern

  WEATHER_CONDITIONS = %w[
    clear_sky
    few_clouds
    scattered_clouds
    broken_clouds
    shower_rain
    rain
    thunderstorm
    snow
    mist
  ].freeze

  included do
    attribute :condition, :string
    validates :condition, inclusion: { in: WEATHER_CONDITIONS }
  end
end
