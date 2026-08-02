import SwiftUI

@main
struct GAPApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = TaskStore.shared
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .environmentObject(settings)
                .tint(.orange)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NotificationManager.shared.registerCategories()
        NotificationManager.shared.requestAuth()
        return true
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationManager.shared.scheduleAllIfNeeded()
    }
}
