require "rails_helper"

RSpec.describe WeatherProviders::OpenWeatherMap do
  let(:test_adapter) { Faraday::Adapter::Test::Stubs.new }
  let(:weather_provider) { described_class.new }
  let(:mock_api_token) { "api-token" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch)
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

  describe "#get_current_weather" do
    let(:location) { LocationData.new(latitude: 40.7128, longitude: -74.0060, name: "New York") }
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
        result = weather_provider.get_current_weather(location)

        expect(result).to be_a(CurrentWeather)
        expect(result.temperature).to eq(22.5)
        expect(result.condition).to eq("clear_sky")
        expect(result.pressure).to eq(1013)
        expect(result.humidity).to eq(65)
      end

      it "calls an API" do
        weather_provider.get_current_weather(location)
        test_adapter.verify_stubbed_calls
      end
    end

    context "when location is invalid" do
      let(:response_code) { 400 }
      let(:api_response) { {} }

      it "raises BadLocationError" do
        expect { weather_provider.get_current_weather(location) }.to raise_error(WeatherProviders::BadLocationError)
      end

      it "calls an API" do
        expect { weather_provider.get_current_weather(location) }.to raise_error(WeatherProviders::BadLocationError)
        test_adapter.verify_stubbed_calls
      end
    end

    context "when API returns non-400 error status" do
      let(:response_code) { 500 }
      let(:api_response) { { "error" => "Server error" } }

      it "raises RequestError" do
        expect { weather_provider.get_current_weather(location) }.to raise_error(WeatherProviders::RequestError)
      end
    end

    context "when location is not LocationData" do
      it "raises ArgumentError" do
        expect { weather_provider.get_current_weather("something") }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#get_weather_forecast" do
    let(:location) { LocationData.new(latitude: 40.7128, longitude: -74.0060, name: "New York") }
    let(:response_code) { 200 }

    before do
      test_adapter.get("/forecast?appid=#{mock_api_token}&lat=40.7128&lon=-74.006&units=metric") do |env|
        [ response_code, {}, api_response ]
      end
    end

    context "when forecast data exists" do
      let(:api_response) do
        {
          "list" => [
            {
              "dt_txt" => "2025-08-05 12:00:00",
              "main" => {
                "temp_min" => 15.0,
                "temp_max" => 20.0,
                "pressure" => 1015,
                "humidity" => 70
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
                "humidity" => 65
              },
              "weather" => [
                {
                  "main" => "Clouds"
                }
              ]
            }
          ]
        }
      end

      it "returns array of ForecastWeather objects" do
        result = weather_provider.get_weather_forecast(location)

        expect(result).to be_an(Array)
        expect(result.first).to be_a(ForecastWeather)
        expect(result.first.date).to eq(Date.parse("2025-08-05"))
        expect(result.first.min_temperature).to eq(15.0)
        expect(result.first.max_temperature).to eq(23.0)
        expect(result.first.condition).to eq("clear_sky")
      end
    end

    context "when location is invalid" do
      let(:response_code) { 400 }
      let(:api_response) { {} }

      it "raises BadLocationError" do
        expect { weather_provider.get_weather_forecast(location) }.to raise_error(WeatherProviders::BadLocationError)
      end
    end

    context "when API returns error status" do
      let(:response_code) { 500 }
      let(:api_response) { { "error" => "Server error" } }

      it "raises RequestError" do
        expect { weather_provider.get_weather_forecast(location) }.to raise_error(WeatherProviders::RequestError)
      end
    end

    context "when location is not LocationData" do
      it "raises ArgumentError" do
        expect { weather_provider.get_weather_forecast("invalid") }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#api_client" do
    before do
      allow(weather_provider).to receive(:api_client).and_call_original
    end
    
    it "configures Faraday with correct base URL and params" do
      client = weather_provider.send(:api_client)

      expect(client.url_prefix.to_s).to eq("https://api.openweathermap.org/data/2.5/")
      expect(client.params[:appid]).to eq(mock_api_token)
    end

    it "includes JSON response middleware" do
      client = weather_provider.send(:api_client)

      expect(client.builder.handlers).to include(Faraday::Response::Json)
    end

    it "includes logger middleware" do
      client = weather_provider.send(:api_client)

      expect(client.builder.handlers).to include(Faraday::Response::Logger)
    end
  end

  describe "#api_token" do
    it "returns the OPENWEATHERMAP_TOKEN environment variable" do
      expect(weather_provider.send(:api_token)).to eq(mock_api_token)
    end

    context "when token is not set" do
      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_TOKEN").and_yield
      end

      it "raises an error" do
        expect { weather_provider.send(:api_token) }.to raise_error("OPENWEATHERMAP_TOKEN environment variable is required")
      end
    end
  end

  after do
  end
end
