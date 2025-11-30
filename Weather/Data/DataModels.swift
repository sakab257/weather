import Foundation
import SwiftData

// MARK: - API DTOs (Decodable)
// These match the Open-Meteo JSON response structure exactly.

struct GeocodingResponse: Decodable {
    let results: [GeoLocation]?
}

struct GeoLocation: Decodable {
    let id: Int
    let name: String
    let country: String?
    let latitude: Double
    let longitude: Double
    let timezone: String?
}

struct OpenMeteoWeatherResponse: Decodable {
    let current: CurrentUnits?
    let hourly: HourlyUnits?
    let daily: DailyUnits?
    let utc_offset_seconds: Int
    
    struct CurrentUnits: Decodable {
        let time: String
        let temperature_2m: Double
        let weather_code: Int
        let is_day: Int
        let wind_speed_10m: Double
        // New fields
        let relative_humidity_2m: Int?
        let apparent_temperature: Double?
    }
    
    struct HourlyUnits: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let weather_code: [Int]
        let relative_humidity_2m: [Int]
        let visibility: [Double]? // OpenMeteo provides visibility in hourly
    }
    
    struct DailyUnits: Decodable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let sunrise: [String]?
        let sunset: [String]?
        let uv_index_max: [Double]? // New field
    }
}

// MARK: - SwiftData Persistence Model
@Model
class SavedCityModel {
    @Attribute(.unique) var compositeID: String
    var id: Int
    var name: String
    var country: String
    var latitude: Double
    var longitude: Double
    var timezone: String?
    var lastUsedDate: Date
    
    // NEW FIELDS
    var lastKnownTemp: Double?
    var lastKnownWeatherCode: Int?
    
    init(city: City) {
        self.id = city.id
        self.name = city.name
        self.country = city.country
        self.latitude = city.latitude
        self.longitude = city.longitude
        self.timezone = city.timezone
        self.lastUsedDate = Date()
        self.compositeID = "\(city.latitude)_\(city.longitude)"
        
        // Save weather if available
        self.lastKnownTemp = city.lastKnownTemp
        self.lastKnownWeatherCode = city.lastKnownWeatherCode
    }
    
    func toDomain() -> City {
        City(
            id: id, name: name, country: country,
            latitude: latitude, longitude: longitude, timezone: timezone,
            lastKnownTemp: lastKnownTemp,
            lastKnownWeatherCode: lastKnownWeatherCode
        )
    }
}
