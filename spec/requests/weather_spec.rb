require 'rails_helper'

RSpec.describe "Weather", type: :request do
  let(:mock_weather_service) { instance_double(WeatherService) }
  let(:location_data) { LocationData.new(latitude: 40.7128, longitude: -74.0060, name: "New York") }
  let(:current_weather) { CurrentWeather.new(temperature: 22.5, condition: 'clear_sky', humidity: 65, pressure: 1013, wind_speed: 5.2, wind_direction: 180) }
  let(:forecast_weather) { [
    ForecastWeather.new(date: Date.current, min_temperature: 18.0, max_temperature: 25.0, condition: 'clear_sky', humidity: 60, pressure: 1015),
    ForecastWeather.new(date: Date.current + 1, min_temperature: 16.0, max_temperature: 23.0, condition: 'few_clouds', humidity: 70, pressure: 1012)
  ] }
  let(:weather_data) { WeatherData.new(
    location: location_data,
    current: current_weather,
    forecast: forecast_weather,
    updated_at: Time.current,
    from_cache: false
  ) }

  before do
    allow(WeatherService).to receive(:new).and_return(mock_weather_service)
  end

  describe "GET /" do
    context "when no location parameter is provided" do
      it "renders successfully" do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "does not call the weather service" do
        get root_path
        expect(WeatherService).not_to have_received(:new)
      end
    end

    context "when location parameter is blank" do
      it "renders successfully" do
        get root_path, params: { location: "" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "does not call the weather service for whitespace" do
        get root_path, params: { location: "   " }
        expect(WeatherService).not_to have_received(:new)
      end
    end

    context "when location parameter is provided" do
      before do
        allow(mock_weather_service).to receive(:get_weather_for_query).with("New York").and_return(weather_data)
      end

      it "renders successfully with weather data" do
        get root_path, params: { location: "New York" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "calls the weather service with the location" do
        get root_path, params: { location: "New York" }
        expect(mock_weather_service).to have_received(:get_weather_for_query).with("New York")
      end

      it "assigns weather data to the view" do
        get root_path, params: { location: "New York" }
        expect(assigns(:weather_data)).to eq(weather_data)
      end

      it "does not set flash messages on success" do
        get root_path, params: { location: "New York" }
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to be_nil
      end
    end


    context "when LocationNotFoundError is raised" do
      before do
        allow(mock_weather_service).to receive(:get_weather_for_query)
          .with("Invalid Location")
          .and_raise(GeocodingProviders::LocationNotFoundError)
      end

      it "renders successfully with error message" do
        get root_path, params: { location: "Invalid Location" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
        expect(assigns(:weather_data)).to be_nil
        expect(flash.now[:alert]).to eq("Location not found. Please try a different city name.")
      end
    end

    context "when a general error is raised" do
      before do
        allow(mock_weather_service).to receive(:get_weather_for_query)
          .with("Error City")
          .and_raise(StandardError.new("API Error"))
        allow(Rails.logger).to receive(:error)
      end

      it "handles the error gracefully and renders template" do
        get root_path, params: { location: "Error City" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
        expect(assigns(:weather_data)).to be_nil
        expect(flash.now[:alert]).to eq("Something went wrong. Please try again later.")
      end
    end

    context "with different location formats" do
      before do
        allow(mock_weather_service).to receive(:get_weather_for_query).and_return(weather_data)
      end

      it "handles city names" do
        get root_path, params: { location: "Paris" }
        expect(response).to have_http_status(:success)
        expect(mock_weather_service).to have_received(:get_weather_for_query).with("Paris")
      end

      it "handles zip codes" do
        get root_path, params: { location: "10001" }
        expect(response).to have_http_status(:success)
        expect(mock_weather_service).to have_received(:get_weather_for_query).with("10001")
      end

      it "handles international locations" do
        get root_path, params: { location: "London, UK" }
        expect(response).to have_http_status(:success)
        expect(mock_weather_service).to have_received(:get_weather_for_query).with("London, UK")
      end
    end
  end
end
