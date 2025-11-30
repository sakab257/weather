import Foundation

protocol NetworkClientProtocol {
    func get<T: Decodable>(url: URL) async throws -> T
}

class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    func get<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AppError.apiError("Server Error")
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding Error: \(error)")
            throw AppError.decoding(error)
        }
    }
}

class OpenMeteoAPI {
    private let client: NetworkClientProtocol
    private let geoBaseURL = "https://geocoding-api.open-meteo.com/v1/search"
    private let weatherBaseURL = "https://api.open-meteo.com/v1/forecast"
    
    init(client: NetworkClientProtocol = NetworkClient()) {
        self.client = client
    }
    
    func searchCities(query: String) async throws -> [GeoLocation] {
        var components = URLComponents(string: geoBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components.url else { throw AppError.invalidURL }
        let response: GeocodingResponse = try await client.get(url: url)
        return response.results ?? []
    }
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> OpenMeteoWeatherResponse {
        var components = URLComponents(string: weatherBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            // Updated Parameters
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,is_day,wind_speed_10m,relative_humidity_2m,apparent_temperature"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code,relative_humidity_2m,visibility"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        
        guard let url = components.url else { throw AppError.invalidURL }
        return try await client.get(url: url)
    }
}
