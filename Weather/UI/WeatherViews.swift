import SwiftUI
import SwiftData
import Charts

// MARK: - Home View
struct WeatherHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WeatherSearchViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(colors: [Color(hex: "1c1c1e"), Color(hex: "2c3e50")], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                VStack(spacing: 24) {
                    
                    FancySearchBar(text: $viewModel.query, isLoading: viewModel.isLoading).padding(.horizontal)
                    
                    if viewModel.query.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                if !viewModel.recentCities.isEmpty {
                                    Text("Recent Searches").font(.headline).foregroundStyle(.white.opacity(0.7)).padding(.horizontal)
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                                        ForEach(viewModel.recentCities) { city in
                                            Button { onCitySelected(city) } label: { GlassCityCard(city: city) }
                                        }
                                    }.padding(.horizontal)
                                } else { EmptyStateView() }
                            }
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.searchResults) { city in
                                    Button { onCitySelected(city) } label: { SearchResultRow(city: city) }
                                }
                            }.padding(.horizontal)
                        }
                    }
                }
            }
            .navigationDestination(for: City.self) { city in CityWeatherView(city: city) }
            .onAppear { viewModel.setHistoryRepo(SearchHistoryRepository(modelContext: modelContext)) }
        }.tint(.white)
    }
    private func onCitySelected(_ city: City) {
        viewModel.selectCity(city)
        navigationPath.append(city)
    }
}

// MARK: - Detail View
struct CityWeatherView: View {
    @State private var viewModel: CityWeatherViewModel
    @Environment(\.dismiss) var dismiss
    
    init(city: City) { _viewModel = State(initialValue: CityWeatherViewModel(city: city)) }
    
    var body: some View {
        ZStack {
            if let weather = viewModel.weather {
                let theme = WeatherTheme.get(for: weather.current.weatherCode, isDay: weather.current.isDay)
                theme.gradient.ignoresSafeArea().animation(.easeInOut(duration: 0.8), value: weather.current.weatherCode)
            } else { Color(hex: "1a2a3a").ignoresSafeArea() }
            
            if viewModel.isLoading { ProgressView().controlSize(.large).tint(.white) }
            else if let error = viewModel.errorMessage {
                ErrorView(message: error) { Task { await viewModel.loadWeather() } }
            } else if let weather = viewModel.weather {
                ScrollView {
                    VStack(spacing: 20) {
                        HeroSection(weather: weather, cityName: viewModel.city.name).padding(.top, 20)
                        HourlyForecastSection(hourly: weather.hourly)
                        DailyForecastSection(daily: weather.daily)
                        WeatherDetailsGrid(current: weather.current).padding(.bottom, 40)
                    }.padding(.horizontal)
                }.scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadWeather() }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 50)
            Image(systemName: "magnifyingglass.circle.fill").font(.system(size: 64)).foregroundStyle(.white.opacity(0.3))
            Text("Find your city").font(.title3.bold()).foregroundStyle(.white.opacity(0.7))
            Text("Search for a city to see the forecast\nand add it to your list.").multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.5)).font(.body)
            Spacer()
        }.frame(maxWidth: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.yellow)
            Text("Something went wrong").font(.headline).foregroundStyle(.white)
            Text(message).font(.caption).foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center).padding(.horizontal)
            Button("Retry", action: retryAction).buttonStyle(.borderedProminent).tint(.white.opacity(0.2))
        }
    }
}

// MARK: - PREVIEWS (For Xcode Canvas)

#Preview("Home") {
    WeatherHomeView()
        .modelContainer(for: SavedCityModel.self, inMemory: true)
}

#Preview("Detail") {
    // Mock Data
    let mockCity = City(id: 1, name: "Paris", country: "France", latitude: 48.85, longitude: 2.35, timezone: "Europe/Paris")
    let mockWeather = CityWeather(
        city: mockCity,
        current: CurrentWeather(temperature: 18, apparentTemperature: 16, weatherCode: 1, isDay: true, windSpeed: 12, humidity: 65, time: Date(), uvIndex: 5, visibility: 10000),
        hourly: [
            HourlyWeather(time: Date(), temperature: 18, weatherCode: 1, humidity: 60),
            HourlyWeather(time: Date().addingTimeInterval(3600), temperature: 19, weatherCode: 2, humidity: 55),
            HourlyWeather(time: Date().addingTimeInterval(7200), temperature: 17, weatherCode: 3, humidity: 62)
        ],
        daily: [
            DailyWeather(date: Date(), weatherCode: 1, maxTemp: 22, minTemp: 14, sunrise: Date(), sunset: Date(), uvIndexMax: 6),
            DailyWeather(date: Date().addingTimeInterval(86400), weatherCode: 3, maxTemp: 20, minTemp: 12, sunrise: Date(), sunset: Date(), uvIndexMax: 4)
        ]
    )
    
    // Create a version of the view that injects data without fetching
    // (Note: To make this work perfectly in a real app, you'd mock the repository, but for visual preview we can force the state if we refactor slightly, or just trust the VM loads fast. Here is a visual stub.)
    
    ZStack {
        WeatherTheme.get(for: 1, isDay: true).gradient.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 20) {
                HeroSection(weather: mockWeather, cityName: "Paris")
                HourlyForecastSection(hourly: mockWeather.hourly)
                DailyForecastSection(daily: mockWeather.daily)
                WeatherDetailsGrid(current: mockWeather.current)
            }.padding(.horizontal)
        }
    }
}
