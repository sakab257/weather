import SwiftUI
import SwiftData

@main
struct WeatherApp: App {
    // 1. Initialize SwiftData container
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: SavedCityModel.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            WeatherHomeView()
        }
        // 2. Inject context into the environment
        .modelContainer(container)
    }
}
