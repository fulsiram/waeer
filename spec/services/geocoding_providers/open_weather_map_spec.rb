require 'rails_helper'

RSpec.describe GeocodingProviders::OpenWeatherMap do
  let(:test_adapter) { Faraday::Adapter::Test::Stubs.new }
  let(:geocoder) { described_class.new }
  let(:mock_api_token) { "api-token" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch)
      .with("OPENWEATHERMAP_TOKEN")
      .and_return("api-token")

    allow(geocoder).to receive(:api_client) do
      Faraday.new do |builder|
        builder.params = {
          appid: mock_api_token
        }
        builder.adapter :test, test_adapter
        builder.response :json
      end
    end
  end

  describe "#geocode" do
    let(:query) { "New York" }
    let(:response_code) { 200 }

    before do
      test_adapter.get("/direct?appid=#{mock_api_token}&q=#{query}&limit=1") do |env|
        [ response_code, {}, api_response ]
      end
    end

    context "when location exists" do
      let(:api_response) do
        [
          {
            "name" => "New York",
            "lat" => 40.7128,
            "lon" => -74.0060,
            "country" => "US",
            "state" => "NY"
          }
        ]
      end

      it "returns LocationData with correct attributes" do
        result = geocoder.geocode('New York')

        expect(result).to be_a(LocationData)
        expect(result.latitude).to eq(40.7128)
        expect(result.longitude).to eq(-74.0060)
        expect(result.name).to eq('New York')
      end
    end

    context "when location does not exist" do
      let(:api_response) do
        []
      end


      it "raises LocationNotFoundError" do
        expect { geocoder.geocode('New York') }.to raise_error(GeocodingProviders::LocationNotFoundError)
      end
    end

    context "when API returns error status" do
      let(:response_code) { 500 }
      let(:api_response) { { "error" => "Server error" } }

      it "raises RequestError" do
        expect { geocoder.geocode('New York') }.to raise_error(GeocodingProviders::RequestError)
      end
    end
  end

  describe "#api_client" do
    before do
      allow(geocoder).to receive(:api_client).and_call_original
    end

    it "configures Faraday with correct base URL and params" do
      client = geocoder.send(:api_client)

      expect(client.url_prefix.to_s).to eq("http://api.openweathermap.org/geo/1.0/")
      expect(client.params[:appid]).to eq(mock_api_token)
    end

    it "includes JSON response middleware" do
      client = geocoder.send(:api_client)

      expect(client.builder.handlers).to include(Faraday::Response::Json)
    end

    it "includes logger middleware" do
      client = geocoder.send(:api_client)

      expect(client.builder.handlers).to include(Faraday::Response::Logger)
    end
  end

  describe "#api_token" do
    it "returns the OPENWEATHERMAP_TOKEN environment variable" do
      expect(geocoder.send(:api_token)).to eq(mock_api_token)
    end

    context "when token is not set" do
      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_TOKEN").and_yield
      end

      it "raises an error" do
        expect { geocoder.send(:api_token) }.to raise_error("OPENWEATHERMAP_TOKEN environment variable is required")
      end
    end
  end

  after do
    test_adapter.verify_stubbed_calls
  end
end
