# WAEER - Weather App Enterprise Edition but in Ruby

A modern weather application built with Ruby on Rails that provides current weather conditions and 5-day forecasts for any location worldwide.

## 🌤️ Features

- **Current Weather Data**: Real-time temperature, humidity, pressure, and wind information
- **5-Day Forecast**: Detailed weather predictions with temperature ranges and conditions
- **Location Search**: Search by city name with intelligent geocoding
- **Smart Caching**: Optimized API usage with Solid Cache (Rails 8)
- **Enterprise Architecture**: Clean, modular service-oriented design

## 🚀 Tech Stack

- **Backend**: Ruby on Rails 8.0
- **Frontend**: Tailwind CSS
- **Cache**: Solid Cache (Rails 8 database-backed caching)
- **HTTP Client**: Faraday
- **Testing**: RSpec, SimpleCov
- **Deployment**: Docker, Docker Compose, Kamal

## 📦 Installation

### Prerequisites
- Ruby 3.4+
- Node.js 18+
- OpenWeatherMap API key ([sign up here](https://openweathermap.org/api))

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/fulsiram/waeer.git
   cd weather-app
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your OpenWeatherMap API key
   ```

4. **Setup database**
   ```bash
   rails db:create db:migrate
   ```

5. **Start the application**
   ```bash
   ./bin/dev
   ```

Visit `http://localhost:3000` to access the application.

## 🐳 Docker Deployment

### Using Docker Compose (Recommended)

1. **Create environment file**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and update `OPENWEATHERMAP_TOKEN` with your actual API key.

2. **Generate Rails secrets**
   ```bash
   echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" >> .env
   ```

3. **Run with Docker Compose**
   ```bash
   docker compose up
   ```

Visit `http://localhost:3000` to access the application.

### Using Docker directly

```bash
docker build -t waeer .
docker run -p 3000:80 -e OPENWEATHERMAP_TOKEN=your_token -e SECRET_KEY_BASE=your_secret_key_base waeer
```

## 🔧 Configuration

### Environment Variables

- `OPENWEATHERMAP_TOKEN`: Your OpenWeatherMap API key (required)
- `SECRET_KEY_BASE`: Rails secret key base (required for production)
- `RAILS_ENV`: Application environment (development/test/production)

## 🧪 Testing

Run the full test suite:

```bash
bundle exec rspec
```

Generate coverage report:
```bash
bundle exec rspec
open coverage/index.html
```

## Object Decomposition

The application is structured around clean separation of concerns:

### Core Models
- **`WeatherData`**: Main aggregate root containing location, current weather, and forecast data
- **`CurrentWeather`**: Current weather conditions (temperature, pressure, humidity, wind)
- **`ForecastWeather`**: Contains daily forecast data
- **`LocationData`**: Geographic data with latitude/longitude coordinates and location name

### Service Layer
- **`WeatherService`**: Orchestrates weather data retrieval, handles caching, and coordinates between providers
- **`WeatherProviders::Base`**: Weather provider interface
- **`WeatherProviders::OpenWeatherMap`**: OpenWeatherMap API implementation
- **`GeocodingProviders::Base`**: Geocoding provider interface
- **`GeocodingProviders::OpenWeatherMap`**: Geocoding implementation for OpenWeatherMap API

### Supporting Components
- **`DataMappers::OpenWeatherMap`**: Transforms external API responses into domain models

## 🔌 API Providers

Currently integrated:
- **OpenWeatherMap**: Weather data and geocoding

Easily extensible to support additional providers like:
- AccuWeather
- Weather.gov
- Custom internal APIs

