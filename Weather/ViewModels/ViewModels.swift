import Foundation
import SwiftData
import SwiftUI

// MARK: - Search ViewModel

@Observable
class WeatherSearchViewModel {
    var query: String = "" {
        didSet {
            // Debounce: Cancel previous task, wait 0.5s, then search
            searchTask?.cancel()
            searchTask = Task {
                if query.isEmpty {
                    searchResults = []
                    return
                }
                try? await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled {
                    await performSearch()
                }
            }
        }
    }
    
    var searchResults: [City] = []
    var recentCities: [City] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    private var searchTask: Task<Void, Never>?
    private let weatherRepo: WeatherRepositoryProtocol
    private var historyRepo: SearchHistoryRepository?
    
    init(weatherRepo: WeatherRepositoryProtocol = WeatherRepository(), historyRepo: SearchHistoryRepository? = nil) {
        self.weatherRepo = weatherRepo
        self.historyRepo = historyRepo
    }
    
    // Called when the view appears or context is ready
    func setHistoryRepo(_ repo: SearchHistoryRepository) {
        self.historyRepo = repo
        loadHistory()
    }
    
    func loadHistory() {
        guard let repo = historyRepo else { return }
        recentCities = repo.loadRecentCities()
    }
    
    func selectCity(_ city: City) {
        historyRepo?.save(city: city)
        loadHistory()
    }
    
    @MainActor
    private func performSearch() async {
        isLoading = true
        errorMessage = nil
        do {
            searchResults = try await weatherRepo.searchCities(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Detail ViewModel

@Observable
class CityWeatherViewModel {
    let city: City
    var weather: CityWeather?
    var isLoading: Bool = false
    var errorMessage: String?

    private let repo: WeatherRepositoryProtocol
    private var historyRepo: SearchHistoryRepository?

    init(city: City, repo: WeatherRepositoryProtocol = WeatherRepository(), historyRepo: SearchHistoryRepository? = nil) {
        self.city = city
        self.repo = repo
        self.historyRepo = historyRepo
    }

    func setHistoryRepo(_ repo: SearchHistoryRepository) {
        self.historyRepo = repo
    }

    func loadWeather() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            // Artificial delay for smoother UX (optional)
            try await Task.sleep(for: .milliseconds(200))
            weather = try await repo.getWeather(for: city)

            // Save city with weather data to history AFTER loading weather
            if let weather = weather {
                var updatedCity = city
                updatedCity.lastKnownTemp = weather.current.temperature
                updatedCity.lastKnownWeatherCode = weather.current.weatherCode
                historyRepo?.save(city: updatedCity)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
