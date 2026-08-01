import SwiftUI

/// 数据看板：完成率趋势 + 统计
struct DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stats = DailyStats.zero

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 统计卡片
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        statCard("📅 打卡天数", stats.totalDays, "天")
                        statCard("🔥 连续打卡", stats.streak, "天")
                        statCard("✅ 总完成率", stats.overallRate, "%")
                        statCard("📤 投简历", stats.resumeDays, "天")
                    }
                    .padding(.horizontal, 12)

                    // 本周趋势图
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本周趋势")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(.leading, 4)

                        if stats.dailyRates.isEmpty {
                            Text("暂无数据")
                                .foregroundColor(Color.white.opacity(0.3))
                                .frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            barChart
                        }
                    }
                    .padding(12)
                    .background(Color(hex: "1e1f23"))
                    .cornerRadius(12)
                    .padding(.horizontal, 12)

                    // 图例
                    HStack(spacing: 16) {
                        legendDot(Color(hex: "57d97c"), "80%以上")
                        legendDot(Color(hex: "f0a040"), "50-79%")
                        legendDot(Color(hex: "ff6b6b"), "低于50%")
                    }
                    .font(.system(size: 10))
                }
                .padding(.vertical, 12)
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

    // MARK: - 柱状图

    private var barChart: some View {
        let maxRate = stats.dailyRates.map(\.rate).max() ?? 10
        let displayMax = max(maxRate, 10)

        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(stats.dailyRates.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 3) {
                    Text("\(Int(day.rate))%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                    Rectangle()
                        .fill(barColor(day.rate))
                        .frame(width: 36, height: max(4, CGFloat(day.rate / displayMax) * 100))
                        .cornerRadius(4)
                    Text(day.label)
                        .font(.system(size: 9))
                        .foregroundColor(Color.white.opacity(0.4))
                }
            }
        }
        .frame(height: 140)
        .padding(.top, 8)
    }

    private func barColor(_ rate: Double) -> Color {
        rate >= 80 ? Color(hex: "57d97c") : (rate >= 50 ? Color(hex: "f0a040") : Color(hex: "ff6b6b"))
    }

    private func statCard(_ title: String, _ value: Int, _ unit: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.4))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "f0a040"))
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(hex: "1e1f23"))
        .cornerRadius(10)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).foregroundColor(Color.white.opacity(0.4))
        }
    }
}

// MARK: - 统计数据

struct DailyStats {
    var totalDays = 0
    var streak = 0
    var overallRate: Double = 0
    var resumeDays = 0
    var dailyRates: [(label: String, rate: Double)] = []

    static let zero = DailyStats()

    static func compute() -> DailyStats {
        var s = DailyStats()
        let checks = UserDefaults.standard.data(forKey: "gap_day_progress")
            .flatMap { try? JSONDecoder().decode(DayProgress.self, from: $0) }
        // Note: checks 结构是单日数据，这里需要完整的历史数据
        // 简化版：从 UserDefaults 读取按日存储的数据
        let allChecks = loadAllChecks()
        let today = Date()
        let tasks = currentTasks

        var totalDone = 0
        var totalTasks = 0

        // 最近7天
        var rates: [(label: String, rate: Double)] = []
        for offset in (0...6).reversed() {
            guard let d = Calendar.current.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = dateKey(d)
            let dayChecks = allChecks[key] ?? [:]
            let done = dayChecks.values.filter { $0 }.count
            let total = tasks.count
            let rate = total > 0 ? Double(done) / Double(total) * 100 : 0
            rates.append((label: "\(Calendar.current.component(.month, from: d))/\(Calendar.current.component(.day, from: d))", rate: rate))
            if done > 0 {
                s.totalDays += 1
                totalDone += done
                totalTasks += total
            }
            if dayChecks["8"] == true { s.resumeDays += 1 }
        }
        s.dailyRates = rates
        s.overallRate = totalTasks > 0 ? Double(totalDone) / Double(totalTasks) * 100 : 0

        // 连续天数
        var streak = 0
        for offset in 0...365 {
            guard let d = Calendar.current.date(byAdding: .day, value: -offset, to: today) else { break }
            let key = dateKey(d)
            if allChecks[key]?.values.contains(true) == true { streak += 1 }
            else { break }
        }
        s.streak = streak

        return s
    }

    private static func dateKey(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-M-d"; return f.string(from: d)
    }

    private static func loadAllChecks() -> [String: [String: Bool]] {
        // 从 .gap_checks.json 结构读取（每个 key 是日期）
        // iOS 端目前用 DayProgress 单日存储，需要改为多日存储
        // 简化：直接用 UserDefaults dictionary
        return UserDefaults.standard.dictionary(forKey: "gap_all_checks") as? [String: [String: Bool]] ?? [:]
    }
}
