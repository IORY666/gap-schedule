import SwiftUI

struct DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stats = DailyStats.zero
    private var tasks: [TaskItem] { TaskStore.shared.tasks }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // 卡片行
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        card("📅 打卡", stats.days, "天")
                        card("🔥 连续", stats.streak, "天")
                        card("✅ 完成率", Int(stats.rate), "%")
                        card("📤 投简历", stats.resume, "天")
                    }

                    // 柱状图
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本周趋势").font(.subheadline).foregroundColor(.secondary)
                        barChart.frame(height: 130)
                    }
                    .padding().background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 16) { dot(.green, "80%+"); dot(.orange, "50-79%"); dot(.red, "<50%") }.font(.caption2)
                }.padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("统计").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("关闭") { dismiss() } } }
        }
        .onAppear {
            var s = DailyStats.zero
            let all = (UserDefaults.standard.dictionary(forKey: "gap_all_checks") as? [String: [String: Bool]]) ?? [:]
            let today = Date()
            let tks = tasks
            var days = 0, streak = 0, resume = 0, totalD = 0, totalT = 0
            var rates: [(String, Double)] = []
            for off in (0...6).reversed() {
                guard let d = Calendar.current.date(byAdding: .day, value: -off, to: today) else { continue }
                let key = dateKey(d)
                let dc = all[key] ?? [:]
                let done = dc.values.filter({ $0 }).count
                let total = tks.count
                let rate = total > 0 ? Double(done)/Double(total)*100 : 0
                rates.append(("\(Calendar.current.component(.month, from: d))/\(Calendar.current.component(.day, from: d))", rate))
                if done > 0 { days += 1; totalD += done; totalT += total }
                if dc["8"] == true { resume += 1 }
            }
            for off in 0...365 {
                guard let d = Calendar.current.date(byAdding: .day, value: -off, to: today) else { break }
                if all[dateKey(d)]?.values.contains(true) == true { streak += 1 } else { break }
            }
            s.days = days; s.streak = streak; s.resume = resume
            s.rate = totalT > 0 ? Double(totalD)/Double(totalT)*100 : 0
            s.rates = rates
            stats = s
        }
    }

    private var barChart: some View {
        let maxV = max(stats.rates.map(\.1).max() ?? 10, 10)
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<stats.rates.count, id: \.self) { i in
                let r = stats.rates[i]
                VStack(spacing: 2) {
                    Text("\(Int(r.1))%").font(.system(size: 9, weight: .bold))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(r.1 >= 80 ? .green : (r.1 >= 50 ? .orange : .red))
                        .frame(width: 38, height: max(4, CGFloat(r.1/maxV) * 100))
                    Text(r.0).font(.system(size: 8)).foregroundColor(.secondary)
                }
            }
        }
    }

    private func card(_ t: String, _ v: Int, _ u: String) -> some View {
        VStack(spacing: 2) {
            Text(t).font(.caption).foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(v)").font(.title).fontWeight(.bold).foregroundColor(.orange)
                Text(u).font(.caption).foregroundColor(.secondary)
            }
        }.padding(.vertical, 8).frame(maxWidth: .infinity).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
    private func dot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 3) { Circle().fill(c).frame(width: 7, height: 7); Text(t).foregroundColor(.secondary) }
    }
    private func dateKey(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-M-d"; return f.string(from: d) }
}

struct DailyStats {
    var days = 0, streak = 0, resume = 0
    var rate: Double = 0
    var rates: [(String, Double)] = []
    static let zero = DailyStats()
}
