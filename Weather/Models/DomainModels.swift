import Foundation

// MARK: - Domain Models

struct City: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timezone: String?
    var lastKnownTemp: Double?
    var lastKnownWeatherCode: Int?
}

struct CityWeather {
    let city: City
    let current: CurrentWeather
    let hourly: [HourlyWeather]
    let daily: [DailyWeather]
}

struct CurrentWeather {
    let temperature: Double
    let apparentTemperature: Double
    let weatherCode: Int
    let isDay: Bool
    let windSpeed: Double
    let humidity: Int
    let time: Date
    // Derived/Passed-through for the grid
    let uvIndex: Double
    let visibility: Double
}

struct HourlyWeather: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Double
    let weatherCode: Int
    let humidity: Int
}

struct DailyWeather: Identifiable {
    let id = UUID()
    let date: Date
    let weatherCode: Int
    let maxTemp: Double
    let minTemp: Double
    let sunrise: Date?
    let sunset: Date?
    let uvIndexMax: Double
}

enum AppError: LocalizedError {
    case network(Error)
    case decoding(Error)
    case apiError(String)
    case invalidURL
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .network(let error): return "Network error: \(error.localizedDescription)"
        case .decoding: return "Data processing failed."
        case .apiError(let msg): return "Server: \(msg)"
        case .invalidURL: return "Invalid Request"
        case .unknown: return "Unknown error"
        }
    }
}
