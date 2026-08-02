import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("今天", systemImage: "sun.max") }.tag(0)

            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("统计", systemImage: "chart.bar.fill") }.tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("设置", systemImage: "gearshape.fill") }.tag(2)
        }
    }
}
