import SwiftUI

@main
struct GapScheduleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

/// 处理通知权限、snooze action 回调
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 注册通知类别（含snooze actions）
        NotificationManager.shared.registerCategories()
        // 每天刷新通知
        NotificationManager.shared.scheduleAllIfNeeded()
        return true
    }
}
