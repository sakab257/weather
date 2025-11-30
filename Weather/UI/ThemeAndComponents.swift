import SwiftUI

// MARK: - Fancy Search Bar
struct FancySearchBar: View {
    @Binding var text: String
    var isLoading: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
            
            // FIX: Use `prompt` with Text() to style the placeholder color
            TextField("", text: $text, prompt: Text("Search City...").foregroundStyle(.white.opacity(0.5)))
                .foregroundStyle(.white)
                .tint(.white)
                .font(.system(size: 18))
            
            if isLoading {
                ProgressView().tint(.white).scaleEffect(0.8)
            } else if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let city: City
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(city.name).font(.title3.bold()).foregroundStyle(.white)
                Text(city.country).font(.subheadline).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Image(systemName: "arrow.up.left").rotationEffect(.degrees(45)).foregroundStyle(.white.opacity(0.5))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))
    }
}

// MARK: - Glass City Card
struct GlassCityCard: View {
    let city: City
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Location Icon + Weather Icon
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.cyan)
                
                Spacer()
                
                // Weather Icon (Top Right)
                if let code = city.lastKnownWeatherCode {
                    Image(systemName: WeatherTheme.get(for: code, isDay: true).mainIcon)
                        .symbolRenderingMode(.multicolor)
                        .font(.title2)
                        .shadow(radius: 4)
                }
            }
            
            Spacer()
            
            // Bottom Row: City Info + Temperature
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(city.country)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Temperature (Next to City)
                if let temp = city.lastKnownTemp {
                    Text("\(Int(temp))°")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
            }
        }
        .padding(16)
        .frame(height: 130)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    let weather: CityWeather
    let cityName: String
    
    var theme: WeatherTheme { WeatherTheme.get(for: weather.current.weatherCode, isDay: weather.current.isDay) }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(cityName).font(.largeTitle.weight(.medium)).foregroundStyle(.white).shadow(radius: 4)
            Text(weather.current.time.formatted(date: .omitted, time: .shortened)).font(.subheadline).foregroundStyle(.white.opacity(0.8)).padding(.top, 4)
            
            Image(systemName: theme.mainIcon)
                .resizable().scaledToFit().symbolRenderingMode(.multicolor)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10).padding(.vertical, 10)
            
            Text("\(Int(weather.current.temperature))°").font(.system(size: 96, weight: .light)).foregroundStyle(.white).shadow(radius: 4)
            Text(weatherDesc(code: weather.current.weatherCode)).font(.title3).foregroundStyle(.white.opacity(0.9)).padding(.bottom, 20)
            
            // Feels Like
            Text("Feels like \(Int(weather.current.apparentTemperature))°")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    func weatherDesc(code: Int) -> String {
        switch code {
        case 0: return "Clear Sky"
        case 1...3: return "Partly Cloudy"
        case 45, 48: return "Foggy"
        case 51...67, 80...82: return "Rainy"
        case 71...77, 85...86: return "Snow"
        case 95...99: return "Thunderstorm"
        default: return "Unknown"
        }
    }
}

// MARK: - Hourly
struct HourlyForecastSection: View {
    let hourly: [HourlyWeather]
    var body: some View {
        VStack(alignment: .leading) {
            Label("24-Hour Forecast", systemImage: "clock").font(.caption.bold()).foregroundStyle(.white.opacity(0.7)).padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(hourly) { item in
                        VStack(spacing: 10) {
                            Text(item.time.formatted(date: .omitted, time: .shortened)).font(.caption2.bold())
                            Image(systemName: WeatherTheme.get(for: item.weatherCode, isDay: true).mainIcon).font(.title2).symbolRenderingMode(.multicolor).frame(height: 30)
                            Text("\(Int(item.temperature))°").font(.title3.bold())
                        }
                        .padding(.vertical, 16).padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 15).fill(.ultraThinMaterial))
                        .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Daily
struct DailyForecastSection: View {
    let daily: [DailyWeather]
    var body: some View {
        VStack(alignment: .leading) {
            Label("7-Day Forecast", systemImage: "calendar").font(.caption.bold()).foregroundStyle(.white.opacity(0.7)).padding(.leading)
            VStack(spacing: 2) {
                ForEach(daily) { day in
                    HStack {
                        Text(day.date.formatted(.dateTime.weekday(.wide))).font(.system(size: 16, weight: .medium)).frame(width: 100, alignment: .leading)
                        Spacer()
                        Image(systemName: WeatherTheme.get(for: day.weatherCode, isDay: true).mainIcon).symbolRenderingMode(.multicolor).font(.title3)
                        Spacer()
                        HStack(spacing: 12) {
                            Text("\(Int(day.minTemp))°").foregroundStyle(.white.opacity(0.5))
                            Capsule().fill(LinearGradient(colors: [.blue.opacity(0.5), .yellow.opacity(0.5)], startPoint: .leading, endPoint: .trailing)).frame(width: 60, height: 4)
                            Text("\(Int(day.maxTemp))°").frame(width: 35, alignment: .trailing)
                        }.font(.system(size: 16, weight: .bold))
                    }
                    .padding().foregroundStyle(.white)
                    if day.id != daily.last?.id { Divider().background(.white.opacity(0.2)).padding(.horizontal) }
                }
            }
            .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)).padding(.horizontal)
        }
    }
}

// MARK: - Details Grid (REAL DATA)
struct WeatherDetailsGrid: View {
    let current: CurrentWeather
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            DetailCell(icon: "wind", title: "Wind", value: "\(Int(current.windSpeed)) km/h")
            DetailCell(icon: "humidity", title: "Humidity", value: "\(current.humidity)%")
            DetailCell(icon: "sun.max", title: "UV Index", value: String(format: "%.0f", current.uvIndex))
            DetailCell(icon: "eye", title: "Visibility", value: "\(Int(current.visibility / 1000)) km")
        }
        .padding(.horizontal)
    }
}

struct DetailCell: View {
    let icon: String
    let title: String
    let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).font(.title2).foregroundStyle(.white.opacity(0.7)).frame(width: 30)
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundStyle(.white.opacity(0.6))
                Text(value).font(.headline).foregroundStyle(.white)
            }
            Spacer()
        }
        .padding().background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
}

struct WeatherTheme: Equatable {
    let gradientColors: [Color]
    let mainIcon: String
    var gradient: LinearGradient { LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing) }
    
    static func get(for code: Int, isDay: Bool) -> WeatherTheme {
        let colors: [Color]
        let icon: String
        switch code {
        case 0: // Clear
            colors = isDay ? [Color(hex: "4facfe"), Color(hex: "00f2fe")] : [Color(hex: "0f2027"), Color(hex: "203a43")]
            icon = isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1...3: // Cloudy
            colors = isDay ? [Color(hex: "a8c0ff"), Color(hex: "3f2b96")] : [Color(hex: "232526"), Color(hex: "414345")]
            icon = "cloud.fill"
        case 45...48: // Fog
            colors = [Color(hex: "3E5151"), Color(hex: "DECBA4")]
            icon = "cloud.fog.fill"
        case 51...67, 80...82: // Rain
            colors = [Color(hex: "000046"), Color(hex: "1CB5E0")]
            icon = "cloud.rain.fill"
        case 95...99: // Thunder
            colors = [Color(hex: "141E30"), Color(hex: "243B55")]
            icon = "cloud.bolt.fill"
        default:
            colors = [Color(hex: "2193b0"), Color(hex: "6dd5ed")]
            icon = "questionmark.circle"
        }
        return WeatherTheme(gradientColors: colors, mainIcon: icon)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
