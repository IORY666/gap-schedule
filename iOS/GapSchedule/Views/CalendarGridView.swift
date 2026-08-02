import SwiftUI

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    @State private var monthOffset = 0

    private var displayMonth: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: startOfMonth(Date())) ?? Date()
    }

    var body: some View {
        VStack(spacing: 4) {
            // 月份导航
            HStack {
                Button(action: { monthOffset -= 1 }) { Image(systemName: "chevron.left").font(.caption) }
                Spacer()
                Text(monthStr(displayMonth)).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Button(action: { monthOffset += 1 }) { Image(systemName: "chevron.right").font(.caption) }
                Button("今天") { monthOffset = 0; selectedDate = Date() }.font(.caption).foregroundColor(.orange)
            }
            // 星期头
            HStack(spacing: 0) {
                ForEach(["日","一","二","三","四","五","六"], id: \.self) { d in
                    Text(d).font(.caption2).fontWeight(.medium)
                        .foregroundColor(d == "六" ? .blue : (d == "日" ? .red : .secondary))
                        .frame(maxWidth: .infinity)
                }
            }
            // 日期网格
            let days = genDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
                ForEach(days, id: \.key) { day in
                    if day.isCurrent, let date = day.date {
                        Button(action: { selectedDate = date }) {
                            Text("\(day.day)")
                                .font(.caption).fontWeight(day.isToday ? .bold : .regular)
                                .foregroundColor(day.isToday ? .white : (day.isSat ? .blue : .primary))
                                .frame(height: 28).frame(maxWidth: .infinity)
                                .background(day.isToday ? Color.orange : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                                .overlay(Group {
                                    if day.isSat && !day.isToday {
                                        Circle().fill(.green).frame(width: 4, height: 4).offset(y: 9)
                                    }
                                })
                        }
                    } else {
                        Text("\(day.day)").font(.caption).foregroundColor(.clear)
                            .frame(height: 28).frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func startOfMonth(_ d: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: d)) ?? d
    }
    private func monthStr(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy年 M月"; return f.string(from: d)
    }
    private func genDays() -> [Day] {
        let first = startOfMonth(displayMonth)
        let wd = Calendar.current.component(.weekday, from: first) - 1
        let cnt = Calendar.current.range(of: .day, in: .month, for: first)?.count ?? 30
        let total = Int(ceil(Double(wd + cnt) / 7)) * 7
        return (0..<total).map { i in
            let d = i - wd + 1
            let ok = d >= 1 && d <= cnt
            let date = ok ? Calendar.current.date(byAdding: .day, value: d - 1, to: first) : nil
            let isSat = date.map { Calendar.current.component(.weekday, from: $0) == 7 } ?? false
            let isToday = date.map { Calendar.current.isDateInToday($0) } ?? false
            return Day(key: "\(i)", day: d, isCurrent: ok, isSat: isSat, isToday: isToday, date: date)
        }
    }

    struct Day { let key: String; let day: Int; let isCurrent: Bool; let isSat: Bool; let isToday: Bool; let date: Date? }
}
