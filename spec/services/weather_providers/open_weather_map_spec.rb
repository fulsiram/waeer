require "rails_helper"

RSpec.describe WeatherProviders::OpenWeatherMap do
  let(:test_adapter) { Faraday::Adapter::Test::Stubs.new }
  let(:weather_provider) { described_class.new }
  let(:mock_api_token) { "api-token" }

  before do
    allow(ENV).to receive(:[])
      .with("OPENWEATHERMAP_TOKEN")
      .and_return("api-token")

    allow(weather_provider).to receive(:api_client) do
      Faraday.new do |builder|
        builder.params = {
          appid: mock_api_token
        }
        builder.adapter :test, test_adapter
        builder.response :json
      end
    end
  end

  describe "#get_weather" do
    let(:location) { LocationData.new(latitude: 40.7128, longtitude: -74.0060, name: "New York") }
    let(:response_code) { 200 }

    before do
      test_adapter.get("/weather?appid=#{mock_api_token}&lat=40.7128&lon=-74.006&units=metric") do |env|
        [ response_code, {}, api_response ]
      end
    end

    context "when location is valid" do
      let(:api_response) do
        {
          "main" => {
            "temp" => 22.5,
            "pressure" => 1013,
            "humidity" => 65
          },
          "weather" => [
            {
              "main" => "Clear",
              "description" => "clear sky"
            }
          ]
        }
      end

      it "returns CurrentWeather with correct attributes" do
        result = weather_provider.get_weather(location)

        expect(result).to be_a(CurrentWeather)
        expect(result.temperature).to eq(22.5)
        expect(result.condition).to eq("clear_sky")
        expect(result.pressure).to eq(1013)
        expect(result.humidity).to eq(65)
      end

      it "calls an API" do
        weather_provider.get_weather(location)
        test_adapter.verify_stubbed_calls
      end
    end

    context "when location is invalid" do
      let(:response_code) { 400 }
      let(:api_response) { {} }

      it "returns CurrentWeather with correct attributes" do
        expect { weather_provider.get_weather(location) }.to raise_error(WeatherProviders::BadLocationError)
      end

      it "calls an API" do
        expect { weather_provider.get_weather(location) }.to raise_error(WeatherProviders::BadLocationError)
        test_adapter.verify_stubbed_calls
      end
    end

    context "when location is not LocationData" do
      it "raises ArgumentError" do
        expect { weather_provider.get_weather("something") }.to raise_error(ArgumentError)
      end
    end
  end

  after do
  end
end
