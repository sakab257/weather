# Weather App - Real-time Weather Forecast

A modern, elegant iOS weather application built with SwiftUI that provides real-time weather forecasts with a beautiful, weather-adaptive interface.

## Features

### Core Functionality
- **City Search**: Search for any city worldwide with intelligent debouncing (500ms) to optimize API calls
- **Recent Searches**: View your last 10 searched cities with cached weather data for instant access
- **Current Weather**: Detailed current conditions including temperature, feels-like temperature, weather description, wind speed, humidity, UV index, and visibility
- **Hourly Forecast**: 24-hour detailed forecast with temperature and weather icons
- **Daily Forecast**: 7-day forecast with min/max temperatures, sunrise/sunset times, and UV index

### User Experience
- **Dynamic Themes**: Background gradients automatically adapt to current weather conditions (clear, cloudy, rainy, snowy, thunderstorm)
- **Day/Night Detection**: Color schemes adjust based on local time of day
- **Glass-morphism UI**: Modern frosted glass effect throughout the interface
- **Smooth Animations**: Fluid transitions between weather states (0.8s gradient animations)
- **Offline Cache**: Recently searched cities display last known temperature and weather without network calls

## Architecture

This application follows the **MVVM (Model-View-ViewModel)** architectural pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│          Presentation Layer                  │
│  (SwiftUI Views & Components)                │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│          ViewModel Layer                     │
│  (@Observable State Management)              │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│      Repository Layer                        │
│  (Business Logic & Data Access)              │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│  Networking + Persistence                    │
│  (Open-Meteo API + SwiftData)                │
└─────────────────────────────────────────────┘
```

### Design Patterns
- **Repository Pattern**: Abstracts data sources (network + local storage)
- **Dependency Injection**: Services injected via constructors for testability
- **Protocol-Oriented Programming**: `NetworkClientProtocol`, `WeatherRepositoryProtocol`
- **Observable Pattern**: Reactive state management with SwiftUI's `@Observable` macro

## Technologies Used

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's new persistence framework for local storage
- **Async/Await**: Modern concurrency for network calls
- **Open-Meteo API**: Free weather data provider
- **Combine**: For debouncing search queries

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd Weather
```

2. Open the project in Xcode:
```bash
open Weather.xcodeproj
```

3. Select your target device (Simulator or physical device)

4. Build and run (⌘ + R)

**Note**: No API key required! The app uses the free [Open-Meteo API](https://open-meteo.com) which doesn't require authentication.

## Project Structure

```
Weather/
├── WeatherApp.swift              # App entry point & SwiftData setup
├── Models/
│   └── DomainModels.swift        # Clean domain models (City, Weather, etc.)
├── Data/
│   ├── DataModels.swift          # API DTOs & SwiftData persistence models
│   └── Repositories.swift        # Data access & business logic
├── Networking/
│   └── NetworkLayer.swift        # Generic HTTP client & Open-Meteo API
├── ViewModels/
│   └── ViewModels.swift          # Observable ViewModels for state management
└── UI/
    ├── WeatherViews.swift        # Main views (Home, Detail, sections)
    └── ThemeAndComponents.swift  # Reusable UI components & theming
```

## API Integration

### Open-Meteo API

The app uses two main endpoints:

**1. Geocoding API** (City Search):
```
GET https://geocoding-api.open-meteo.com/v1/search
?name={query}&count=10&language=en&format=json
```

**2. Weather Forecast API**:
```
GET https://api.open-meteo.com/v1/forecast
?latitude={lat}&longitude={lon}
&current=temperature_2m,weather_code,is_day,wind_speed_10m,relative_humidity_2m,apparent_temperature
&hourly=temperature_2m,weather_code,relative_humidity_2m,visibility
&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max
&timezone=auto&forecast_days=7
```

### Data Flow

1. User searches for a city → Debounced query (500ms)
2. Geocoding API returns city coordinates
3. User selects city → Navigation to detail view
4. Weather API fetches forecast data
5. Data transformed to domain models
6. City + weather data saved to SwiftData
7. UI updates reactively via `@Observable`

## Key Features Implementation

### Search Debouncing
```swift
var query: String = "" {
    didSet {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled {
                await performSearch()
            }
        }
    }
}
```

### Weather-Adaptive Themes
Weather codes (WMO standard 0-99) are mapped to:
- Custom gradient backgrounds (day/night variants)
- Appropriate SF Symbols icons
- Smooth color transitions

### Recent Searches Caching
- Cities stored with composite ID: `{latitude}_{longitude}`
- Prevents duplicate entries
- Last known temperature + weather code cached for instant display
- Sorted by `lastUsedDate` (most recent first)
- Limit: 10 cities

## Future Enhancements

Potential improvements for future versions:

- [ ] Weather data caching with TTL (time-to-live)
- [ ] Pull-to-refresh functionality
- [ ] Location-based "Current Location" weather
- [ ] Weather alerts and notifications
- [ ] Multiple language support (i18n)
- [ ] Dark mode manual toggle
- [ ] Widget support for Home Screen
- [ ] Weather maps integration
- [ ] Unit tests and UI tests
- [ ] Accessibility improvements (VoiceOver support)

## License

This project is available for educational purposes.

## Acknowledgments

- Weather data provided by [Open-Meteo](https://open-meteo.com)
- Weather icons use SF Symbols (Apple's system icon library)
- WMO Weather Codes standard for weather condition classification

---

**Built with SwiftUI**
