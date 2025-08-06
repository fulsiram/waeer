require 'rails_helper'

RSpec.describe GeocodingProviders::OpenWeatherMap do
  let(:test_adapter) { Faraday::Adapter::Test::Stubs.new }
  let(:geocoder) { described_class.new }
  let(:mock_api_token) { "api-token" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[])
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

    before do
      test_adapter.get("/direct?appid=#{mock_api_token}&q=#{query}&limit=1") do |env|
        [ 200, {}, api_response ]
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
        expect(result.longtitude).to eq(-74.0060)
        expect(result.name).to eq('New York')
      end
    end

    context "when location does not exist" do
      let(:api_response) do
        []
      end


      it "raises LocationNotFoundError" do
        expect { geocoder.geocode('New York') }.to raise_error(GeocodingProviders::Base::LocationNotFoundError)
      end
    end
  end

  after do
    test_adapter.verify_stubbed_calls
  end
end
