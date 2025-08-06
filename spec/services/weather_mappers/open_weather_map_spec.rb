require 'rails_helper'

RSpec.describe WeatherMappers::OpenWeatherMap do
  describe ".map_current_weather" do
    let(:api_response) do
      {
        "main" => {
          "temp" => 22.5,
          "pressure" => 1013,
          "humidity" => 65
        },
        "weather" => [
          {
            "main" => "Clear"
          }
        ]
      }
    end

    it "maps API response to CurrentWeather object" do
      result = described_class.map_current_weather(api_response)

      expect(result).to be_a(CurrentWeather)
      expect(result.temperature).to eq(22.5)
      expect(result.condition).to eq("clear_sky")
      expect(result.pressure).to eq(1013)
      expect(result.humidity).to eq(65)
    end
  end

  describe ".map_forecast_weather" do
    let(:api_response) do
      {
        "list" => [
          {
            "dt_txt" => "2025-08-05 12:00:00",
            "main" => {
              "temp_min" => 15.0,
              "temp_max" => 20.0,
              "pressure" => 1015,
              "humidity" => 100
            },
            "weather" => [
              {
                "main" => "Clear"
              }
            ]
          },
          {
            "dt_txt" => "2025-08-05 15:00:00",
            "main" => {
              "temp_min" => 18.0,
              "temp_max" => 23.0,
              "pressure" => 1013,
              "humidity" => 50
            },
            "weather" => [
              {
                "main" => "Rain"
              }
            ]
          },
          {
            "dt_txt" => "2025-08-06 12:00:00",
            "main" => {
              "temp_min" => 12.0,
              "temp_max" => 17.0,
              "pressure" => 1020,
              "humidity" => 80
            },
            "weather" => [
              {
                "main" => "Snow"
              }
            ]
          }
        ]
      }
    end

    it "groups hourly forecasts by day and aggregates data" do
      result = described_class.map_forecast_weather(api_response)

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)

      first_day = result.find { |f| f.date == Date.parse("2025-08-05") }
      expect(first_day).to be_a(ForecastWeather)
      expect(first_day.min_temperature).to eq(15.0)
      expect(first_day.max_temperature).to eq(23.0)
      expect(first_day.pressure).to eq(1014)
      expect(first_day.humidity).to eq(75)
      expect(first_day.condition).to eq("clear_sky")

      second_day = result.find { |f| f.date == Date.parse("2025-08-06") }
      expect(second_day).to be_a(ForecastWeather)
      expect(second_day.min_temperature).to eq(12.0)
      expect(second_day.max_temperature).to eq(17.0)
      expect(second_day.pressure).to eq(1020)
      expect(second_day.humidity).to eq(80)
      expect(second_day.condition).to eq("snow")
    end

    context "when API response is empty" do
      let(:api_response) { { "list" => [] } }

      it "returns empty array" do
        result = described_class.map_forecast_weather(api_response)
        expect(result).to eq([])
      end
    end
  end

  describe ".map_weather_condition" do
    it "maps OpenWeatherMap conditions to internal enum values" do
      expect(described_class.send(:map_weather_condition, "Clear")).to eq(:clear_sky)
      expect(described_class.send(:map_weather_condition, "Clouds")).to eq(:few_clouds)
      expect(described_class.send(:map_weather_condition, "Rain")).to eq(:rain)
      expect(described_class.send(:map_weather_condition, "Snow")).to eq(:snow)
      expect(described_class.send(:map_weather_condition, "Unknown")).to eq(:clear_sky)
    end
  end
end
