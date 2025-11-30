import Foundation
import SwiftData

protocol WeatherRepositoryProtocol {
    func searchCities(query: String) async throws -> [City]
    func getWeather(for city: City) async throws -> CityWeather
}

class WeatherRepository: WeatherRepositoryProtocol {
    private let api: OpenMeteoAPI
    
    init(api: OpenMeteoAPI = OpenMeteoAPI()) {
        self.api = api
    }
    
    func searchCities(query: String) async throws -> [City] {
        let results = try await api.searchCities(query: query)
        return results.map {
            City(id: $0.id, name: $0.name, country: $0.country ?? "Unknown", latitude: $0.latitude, longitude: $0.longitude, timezone: $0.timezone)
        }
    }
    
    func getWeather(for city: City) async throws -> CityWeather {
        let response = try await api.fetchWeather(latitude: city.latitude, longitude: city.longitude)
        return mapResponseToDomain(city: city, response: response)
    }
    
    private func mapResponseToDomain(city: City, response: OpenMeteoWeatherResponse) -> CityWeather {
        // 1. Hourly/Current Formatter (ISO 8601-ish with T)
        let hourlyFormatter = DateFormatter()
        hourlyFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        hourlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        hourlyFormatter.timeZone = TimeZone(identifier: city.timezone ?? "UTC") ?? .current
        
        // 2. Daily Formatter (YYYY-MM-DD) - FIXES THE SUNDAY BUG
        let dailyFormatter = DateFormatter()
        dailyFormatter.dateFormat = "yyyy-MM-dd"
        dailyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dailyFormatter.timeZone = TimeZone(identifier: city.timezone ?? "UTC") ?? .current
        
        func parseHourlyDate(_ str: String) -> Date { hourlyFormatter.date(from: str) ?? Date() }
        func parseDailyDate(_ str: String) -> Date { dailyFormatter.date(from: str) ?? Date() }
        
        // Extract extra data for current view
        let todayUV = response.daily?.uv_index_max?.first ?? 0.0
        let currentVisibility = response.hourly?.visibility?.first ?? 10000.0 // Default to clear if missing
        
        // Current
        let current = CurrentWeather(
            temperature: response.current?.temperature_2m ?? 0,
            apparentTemperature: response.current?.apparent_temperature ?? 0,
            weatherCode: response.current?.weather_code ?? 0,
            isDay: response.current?.is_day == 1,
            windSpeed: response.current?.wind_speed_10m ?? 0,
            humidity: response.current?.relative_humidity_2m ?? 0,
            time: parseHourlyDate(response.current?.time ?? ""),
            uvIndex: todayUV,
            visibility: currentVisibility
        )
        
        // Hourly
        var hourly: [HourlyWeather] = []
        if let h = response.hourly {
            let count = min(h.time.count, 25)
            for i in 0..<count {
                hourly.append(HourlyWeather(
                    time: parseHourlyDate(h.time[i]),
                    temperature: h.temperature_2m[i],
                    weatherCode: h.weather_code[i],
                    humidity: h.relative_humidity_2m[i]
                ))
            }
        }
        
        // Daily
        var daily: [DailyWeather] = []
        if let d = response.daily {
            for i in 0..<d.time.count {
                daily.append(DailyWeather(
                    date: parseDailyDate(d.time[i]),
                    weatherCode: d.weather_code[i],
                    maxTemp: d.temperature_2m_max[i],
                    minTemp: d.temperature_2m_min[i],
                    sunrise: parseHourlyDate(d.sunrise?[i] ?? ""), // Sunrise is usually full timestamp
                    sunset: parseHourlyDate(d.sunset?[i] ?? ""),
                    uvIndexMax: d.uv_index_max?[i] ?? 0
                ))
            }
        }
        
        return CityWeather(city: city, current: current, hourly: hourly, daily: daily)
    }
}

// Keep History Repository same as before
@MainActor
class SearchHistoryRepository {
    private let modelContext: ModelContext
    init(modelContext: ModelContext) { self.modelContext = modelContext }
    
    func loadRecentCities() -> [City] {
        let descriptor = FetchDescriptor<SavedCityModel>(sortBy: [SortDescriptor(\.lastUsedDate, order: .reverse)])
        return (try? modelContext.fetch(descriptor))?.map { $0.toDomain() } ?? []
    }
    
    func save(city: City) {
        let compositeID = "\(city.latitude)_\(city.longitude)"
        let descriptor = FetchDescriptor<SavedCityModel>(predicate: #Predicate { $0.compositeID == compositeID })
        
        let context = modelContext
        if let existing = try? context.fetch(descriptor).first {
            existing.lastUsedDate = Date()
            // Update weather if provided
            if let t = city.lastKnownTemp { existing.lastKnownTemp = t }
            if let c = city.lastKnownWeatherCode { existing.lastKnownWeatherCode = c }
        } else {
            context.insert(SavedCityModel(city: city))
        }
        try? context.save()
    }
}
