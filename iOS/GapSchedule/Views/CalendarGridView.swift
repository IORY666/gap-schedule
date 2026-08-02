import SwiftUI

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    @State private var monthOffset = 0

    private var displayMonth: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: startOfMonth(Date())) ?? Date()
    }

    var body: some View {
        VStack(spacing: 6) {
            // 月份导航
            HStack {
                Button(action: { monthOffset -= 1 }) {
                    Image(systemName: "chevron.left").foregroundColor(.gray)
                }
                Spacer()
                Text(monthString(displayMonth))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { monthOffset += 1 }) {
                    Image(systemName: "chevron.right").foregroundColor(.gray)
                }
                Button("今天") {
                    monthOffset = 0
                    selectedDate = Date()
                }
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "f0a040"))
            }
            .padding(.horizontal, 6)

            // 星期头
            HStack(spacing: 0) {
                ForEach(["日","一","二","三","四","五","六"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(d == "六" ? Color(hex: "74c0fc") : (d == "日" ? Color(hex: "ff6b6b") : .gray))
                        .frame(maxWidth: .infinity)
                }
            }

            // 日期网格
            let days = generateDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(days, id: \.key) { day in
                    DayCell(day: day, selectedDate: $selectedDate)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "1e1f23"))
        .cornerRadius(12)
    }

    // MARK: - 辅助

    private func startOfMonth(_ date: Date) -> Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: comps) ?? date
    }

    private func monthString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy年 M月"; return f.string(from: date)
    }

    private func generateDays() -> [DayData] {
        let monthStart = startOfMonth(displayMonth)
        let firstWeekday = Calendar.current.component(.weekday, from: monthStart) - 1
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let totalCells = Int(ceil(Double(firstWeekday + daysInMonth) / 7)) * 7

        var result: [DayData] = []
        for i in 0..<totalCells {
            let day = i - firstWeekday + 1
            let isCurrentMonth = day >= 1 && day <= daysInMonth
            let date: Date? = isCurrentMonth
                ? Calendar.current.date(byAdding: .day, value: day - 1, to: monthStart)
                : nil
            let isSat = date.map { Calendar.current.component(.weekday, from: $0) == 7 } ?? false
            let isToday = date.map { Calendar.current.isDateInToday($0) } ?? false
            let key = "\(i)_\(day)"

            result.append(DayData(key: key, day: day, isCurrentMonth: isCurrentMonth,
                                  isSaturday: isSat, isToday: isToday, date: date))
        }
        return result
    }

    struct DayData {
        let key: String; let day: Int; let isCurrentMonth: Bool
        let isSaturday: Bool; let isToday: Bool; let date: Date?
    }
}

struct DayCell: View {
    let day: CalendarGridView.DayData
    @Binding var selectedDate: Date
    @EnvironmentObject var manager: ScheduleManager

    var body: some View {
        Group {
            if day.isCurrentMonth, let date = day.date {
                Button(action: { selectedDate = date }) {
                    Text("\(day.day)")
                        .font(.system(size: 13, weight: day.isToday ? .bold : .regular))
                        .foregroundColor(textColor)
                        .frame(height: 30)
                        .frame(maxWidth: .infinity)
                        .background(bgColor)
                        .cornerRadius(6)
                        .overlay(
                            Group {
                                if day.isSaturday && day.isCurrentMonth {
                                    Circle().fill(Color(hex: "57d97c"))
                                        .frame(width: 4, height: 4)
                                        .offset(y: 10)
                                }
                            }
                        )
                }
            } else {
                Text("\(day.day)")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.15))
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var textColor: Color {
        if day.isToday { return .black }
        if day.isSaturday { return Color(hex: "74c0fc") }
        if Calendar.current.component(.weekday, from: day.date ?? Date()) == 1 { return Color(hex: "ff6b6b") }
        return .white
    }

    private var bgColor: Color {
        if day.isToday { return Color(hex: "f0a040") }
        if day.date.map({ Calendar.current.isDate($0, inSameDayAs: selectedDate) }) ?? false {
            return Color.white.opacity(0.1)
        }
        return .clear
    }
}
