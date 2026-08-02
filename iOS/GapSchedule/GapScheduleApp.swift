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
        // 注册通知类别
        NotificationManager.shared.registerCategories()
        // 请求权限 → 权限拿到后自动安排通知
        NotificationManager.shared.requestAuth()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // 每次从后台回到前台时刷新通知
        NotificationManager.shared.scheduleAllIfNeeded()
    }
}
