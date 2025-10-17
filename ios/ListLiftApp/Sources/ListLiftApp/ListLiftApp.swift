import SwiftUI

@main
struct ListLiftApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
                .task {
                    await environment.bootstrap()
                }
        }
    }
}
