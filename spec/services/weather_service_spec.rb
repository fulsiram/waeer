require 'rails_helper'

RSpec.describe WeatherService do
  let(:mock_weather_provider) { instance_double(WeatherProviders::OpenWeatherMap) }
  let(:mock_geocoding_provider) { instance_double(GeocodingProviders::OpenWeatherMap) }
  let(:weather_service) do
    WeatherService.new(
      weather_provider: mock_weather_provider,
      geocoding_provider: mock_geocoding_provider
    )
  end

  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let(:cache) { Rails.cache }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  let(:location_data) { LocationData.new(latitude: 40.7128, longitude: -74.0060, name: "New York") }
  let(:current_weather) { CurrentWeather.new(temperature: 22.5, condition: 'clear_sky', humidity: 65, pressure: 1013, wind_speed: 5.2, wind_direction: 180) }
  let(:forecast_weather) { [
    ForecastWeather.new(date: Date.current, min_temperature: 18.0, max_temperature: 25.0, condition: 'clear_sky', humidity: 60, pressure: 1015),
    ForecastWeather.new(date: Date.current + 1, min_temperature: 16.0, max_temperature: 23.0, condition: 'few_clouds', humidity: 70, pressure: 1012)
  ] }

  describe "#get_weather_for_query" do
    context "when query is blank" do
      it "raises ArgumentError" do
        expect {
          weather_service.get_weather_for_query("")
        }.to raise_error(ArgumentError)
      end
    end

    context "when query is present" do
      let(:query) { "New York" }

      before do
        allow(mock_geocoding_provider).to receive(:geocode).with(query).and_return(location_data)
        allow(mock_weather_provider).to receive(:get_current_weather).with(location_data).and_return(current_weather)
        allow(mock_weather_provider).to receive(:get_weather_forecast).with(location_data).and_return(forecast_weather)
      end

      it "geocodes the query" do
        weather_service.get_weather_for_query(query)
        expect(mock_geocoding_provider).to have_received(:geocode).with(query)
      end

      it "fetches current weather" do
        weather_service.get_weather_for_query(query)
        expect(mock_weather_provider).to have_received(:get_current_weather).with(location_data)
      end

      it "fetches weather forecast" do
        weather_service.get_weather_for_query(query)
        expect(mock_weather_provider).to have_received(:get_weather_forecast).with(location_data)
      end

      it "returns WeatherData object" do
        result = weather_service.get_weather_for_query(query)
        expect(result).to be_a(WeatherData)
        expect(result.location).to eq(location_data)
        expect(result.current).to eq(current_weather)
        expect(result.forecast).to eq(forecast_weather)
        expect(result.updated_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context "with caching" do
      let(:query) { "New York" }
      let(:geocoding_cache_key) { "geocoding:new york" }
      let(:weather_cache_key) { "weather:40.7128:-74.006" }

      before do
        allow(mock_geocoding_provider).to receive(:geocode).with(query).and_return(location_data)
        allow(mock_weather_provider).to receive(:get_current_weather).with(location_data).and_return(current_weather)
        allow(mock_weather_provider).to receive(:get_weather_forecast).with(location_data).and_return(forecast_weather)
      end

      it "caches geocoding results for 24 hours" do
        allow(Rails.cache).to receive(:fetch).and_call_original
        expect(Rails.cache).to receive(:fetch).with(geocoding_cache_key, expires_in: 24.hours).and_call_original
        weather_service.get_weather_for_query(query)
      end

      it "caches weather results for 30 minutes" do
        allow(Rails.cache).to receive(:fetch).and_call_original
        expect(Rails.cache).to receive(:fetch).with(weather_cache_key, expires_in: 30.minutes).and_call_original
        weather_service.get_weather_for_query(query)
      end

      context "when data is not cached" do
        it "calls geocoding provider" do
          weather_service.get_weather_for_query(query)
          expect(mock_geocoding_provider).to have_received(:geocode).with(query)
        end

        it "calls weather provider for current weather" do
          weather_service.get_weather_for_query(query)
          expect(mock_weather_provider).to have_received(:get_current_weather).with(location_data)
        end

        it "calls weather provider for forecast" do
          weather_service.get_weather_for_query(query)
          expect(mock_weather_provider).to have_received(:get_weather_forecast).with(location_data)
        end

        it "sets from_cache to false" do
          result = weather_service.get_weather_for_query(query)
          expect(result.from_cache).to be false
        end

        it "stores geocoding result in cache" do
          weather_service.get_weather_for_query(query)
          cached_location = Rails.cache.read(geocoding_cache_key)
          expect(cached_location.latitude).to eq(location_data.latitude)
          expect(cached_location.longitude).to eq(location_data.longitude)
          expect(cached_location.name).to eq(location_data.name)
        end

        it "stores weather result in cache" do
          result = weather_service.get_weather_for_query(query)
          cached_result = Rails.cache.read(weather_cache_key)
          expect(cached_result.location.latitude).to eq(result.location.latitude)
          expect(cached_result.location.longitude).to eq(result.location.longitude)
          expect(cached_result.location.name).to eq(result.location.name)
          expect(cached_result.current.temperature).to eq(result.current.temperature)
          expect(cached_result.current.condition).to eq(result.current.condition)
        end
      end

      context "when data is cached" do
        let(:cached_weather_data) do
          WeatherData.new(
            location: location_data,
            current: current_weather,
            forecast: forecast_weather,
            updated_at: 1.hour.ago
          )
        end

        before do
          Rails.cache.write(geocoding_cache_key, location_data, expires_in: 24.hours)
          Rails.cache.write(weather_cache_key, cached_weather_data, expires_in: 30.minutes)
        end

        it "returns cached weather data" do
          result = weather_service.get_weather_for_query(query)
          expect(result.location.latitude).to eq(cached_weather_data.location.latitude)
          expect(result.location.longitude).to eq(cached_weather_data.location.longitude)
          expect(result.location.name).to eq(cached_weather_data.location.name)
          expect(result.current.temperature).to eq(cached_weather_data.current.temperature)
          expect(result.current.condition).to eq(cached_weather_data.current.condition)
          expect(result.updated_at).to be_within(1.second).of(cached_weather_data.updated_at)
        end

        it "sets from_cache to true" do
          result = weather_service.get_weather_for_query(query)
          expect(result.from_cache).to be true
        end

        it "does not call weather provider for current weather" do
          weather_service.get_weather_for_query(query)
          expect(mock_weather_provider).not_to have_received(:get_current_weather)
        end

        it "does not call weather provider for forecast" do
          weather_service.get_weather_for_query(query)
          expect(mock_weather_provider).not_to have_received(:get_weather_forecast)
        end
      end
    end
  end

  describe "#get_weather_data" do
    before do
      allow(mock_weather_provider).to receive(:get_current_weather).with(location_data).and_return(current_weather)
      allow(mock_weather_provider).to receive(:get_weather_forecast).with(location_data).and_return(forecast_weather)
    end

    it "fetches current weather from provider" do
      weather_service.send(:get_weather_data, location_data)
      expect(mock_weather_provider).to have_received(:get_current_weather).with(location_data)
    end

    it "fetches forecast weather from provider" do
      weather_service.send(:get_weather_data, location_data)
      expect(mock_weather_provider).to have_received(:get_weather_forecast).with(location_data)
    end

    it "returns WeatherData with all components" do
      result = weather_service.send(:get_weather_data, location_data)
      expect(result).to be_a(WeatherData)
      expect(result.location).to eq(location_data)
      expect(result.current).to eq(current_weather)
      expect(result.forecast).to eq(forecast_weather)
      expect(result.updated_at).to be_within(1.second).of(Time.current)
    end
  end
end
