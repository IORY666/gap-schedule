import SwiftUI

struct DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stats = DailyStats.zero

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    // 统计卡片
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        card("📅 打卡天数", stats.totalDays, "天")
                        card("🔥 连续打卡", stats.streak, "天")
                        card("✅ 完成率", Int(stats.overallRate), "%")
                        card("📤 投简历", stats.resumeDays, "天")
                    }
                    .padding(.horizontal, 12)

                    // 柱状图
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本周趋势").font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.6)).padding(.leading, 4)
                        barChartView
                    }
                    .padding(12).background(Color(hex: "1e1f23")).cornerRadius(12)
                    .padding(.horizontal, 12)

                    // 图例
                    HStack(spacing: 16) {
                        dot(Color(hex: "57d97c"), "80%+")
                        dot(Color(hex: "f0a040"), "50-79%")
                        dot(Color(hex: "ff6b6b"), "<50%")
                    }.font(.system(size: 10))
                }.padding(.vertical, 12)
            }
            .background(Color(hex: "1a1b1e"))
            .navigationTitle("📊 数据看板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { stats = DailyStats.compute() }
    }

    private var barChartView: some View {
        let maxVal = max(stats.dailyRates.map(\.rate).max() ?? 10, 10)
        return HStack(alignment: .bottom, spacing: 5) {
            ForEach(0..<stats.dailyRates.count, id: \.self) { i in
                let day = stats.dailyRates[i]
                VStack(spacing: 3) {
                    Text("\(Int(day.rate))%").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(day.rate >= 80 ? Color(hex: "57d97c") : (day.rate >= 50 ? Color(hex: "f0a040") : Color(hex: "ff6b6b")))
                        .frame(width: 38, height: max(4, CGFloat(day.rate / maxVal) * 100))
                    Text(day.label).font(.system(size: 9)).foregroundColor(Color.white.opacity(0.4))
                }
            }
        }.frame(height: 140).padding(.top, 8)
    }

    private func card(_ title: String, _ val: Int, _ unit: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.system(size: 10)).foregroundColor(Color.white.opacity(0.4))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(val)").font(.system(size: 24, weight: .bold)).foregroundColor(Color(hex: "f0a040"))
                Text(unit).font(.system(size: 12)).foregroundColor(Color.white.opacity(0.5))
            }
        }.frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color(hex: "1e1f23")).cornerRadius(10)
    }

    private func dot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(c).frame(width: 7, height: 7)
            Text(t).foregroundColor(Color.white.opacity(0.4))
        }
    }
}

// MARK: - 统计

struct DailyStats {
    var totalDays = 0, streak = 0, resumeDays = 0
    var overallRate: Double = 0
    var dailyRates: [(label: String, rate: Double)] = []
    static let zero = DailyStats()

    static func compute() -> DailyStats {
        var s = DailyStats()
        let all = (UserDefaults.standard.dictionary(forKey: "gap_all_checks") as? [String: [String: Bool]]) ?? [:]
        let today = Date()
        let tasks = TaskStore.shared.tasks
        var totalDone = 0, totalTasks = 0

        var rates: [(String, Double)] = []
        for off in (0...6).reversed() {
            guard let d = Calendar.current.date(byAdding: .day, value: -off, to: today) else { continue }
            let key = dateKey(d)
            let dc = all[key] ?? [:]
            let done = dc.values.filter({ $0 }).count
            let total = tasks.count
            let rate = total > 0 ? Double(done)/Double(total)*100 : 0
            rates.append(("\(Calendar.current.component(.month, from: d))/\(Calendar.current.component(.day, from: d))", rate))
            if done > 0 { s.totalDays += 1; totalDone += done; totalTasks += total }
            if dc["8"] == true { s.resumeDays += 1 }
        }
        s.dailyRates = rates
        s.overallRate = totalTasks > 0 ? Double(totalDone)/Double(totalTasks)*100 : 0

        var streak = 0
        for off in 0...365 {
            guard let d = Calendar.current.date(byAdding: .day, value: -off, to: today) else { break }
            if all[dateKey(d)]?.values.contains(true) == true { streak += 1 } else { break }
        }
        s.streak = streak
        return s
    }

    private static func dateKey(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-M-d"; return f.string(from: d)
    }
}
