import Foundation

/// 单个任务定义
struct TaskItem: Identifiable, Codable {
    let id: Int
    let emoji: String
    let timeRange: String    // "07:00-07:45"
    let name: String
    let detail: String

    var startHour: Int { Int(timeRange.split(separator: "-")[0].split(separator: ":")[0]) ?? 0 }
    var startMin:  Int { Int(timeRange.split(separator: "-")[0].split(separator: ":")[1]) ?? 0 }
    var endHour:   Int { Int(timeRange.split(separator: "-")[1].split(separator: ":")[0]) ?? 0 }
    var endMin:    Int { Int(timeRange.split(separator: "-")[1].split(separator: ":")[1]) ?? 0 }

    var startMinutes: Int { startHour * 60 + startMin }
    var endMinutes:   Int { endHour * 60 + endMin }

    /// 语音播报文本
    var speechText: String {
        switch id {
        case 0:  return "空腹有氧运动"
        case 1:  return "洗漱整理"
        case 2:  return "去买菜"
        case 3:  return "吃早餐"
        case 4:  return "开始上午的面试题复习"
        case 5:  return "做午饭"
        case 6:  return "午餐后记得午休"
        case 7:  return "开始下午的面试题复习"
        case 8:  return "投简历，每天5到10家"
        case 9:  return "做晚饭"
        case 10: return "吃完晚饭休息一下"
        case 11: return "力量训练加有氧运动"
        case 12: return "洗漱放松准备休息"
        case 13: return "该睡觉了，放下手机"
        default: return name
        }
    }

    /// 提前10分钟预告语音
    var pre10Speech: String { "10分钟后，\(speechText)" }
    /// 提前5分钟预告语音
    var pre5Speech: String { "5分钟后，\(speechText)" }
    /// 到点语音
    var nowSpeech: String {
        id == 13 ? "该睡觉了，放下手机" : "该\(speechText)了"
    }
}

/// 每日完成状态
struct DayProgress: Codable {
    var checked: Set<Int> = []      // 已完成的任务ID
    var dismissed: Set<Int> = []    // "离开"的任务ID
}

/// 提醒模式
enum ReminderMode: String, CaseIterable {
    case tenMin = "提前10分钟"
    case fiveMin = "提前5分钟"
    case onTime = "到点"
}

// MARK: - 全局任务数据

let allTasks: [TaskItem] = [
    TaskItem(id: 0,  emoji: "🏃", timeRange: "07:00-07:45", name: "空腹有氧45min",     detail: "快走/慢跑/跳绳"),
    TaskItem(id: 1,  emoji: "🧹", timeRange: "07:45-08:00", name: "洗漱整理",           detail: "冲澡换衣服"),
    TaskItem(id: 2,  emoji: "🛒", timeRange: "08:00-08:30", name: "买菜",               detail: "菜市场/超市"),
    TaskItem(id: 3,  emoji: "☕", timeRange: "08:30-09:00", name: "早餐",               detail: "健康早餐+蛋白质"),
    TaskItem(id: 4,  emoji: "📖", timeRange: "09:00-11:30", name: "背面试题 · 上午",    detail: "专注刷题2.5小时"),
    TaskItem(id: 5,  emoji: "🍳", timeRange: "11:30-12:30", name: "做午饭",             detail: "简单营养午餐"),
    TaskItem(id: 6,  emoji: "🍽️", timeRange: "12:30-14:00", name: "午餐 + 午休",       detail: "饭后午睡30分钟"),
    TaskItem(id: 7,  emoji: "📖", timeRange: "14:00-16:00", name: "背面试题 · 下午",    detail: "专注刷题2小时"),
    TaskItem(id: 8,  emoji: "📤", timeRange: "16:00-17:00", name: "投简历",             detail: "Boss/拉钩/脉脉 5-10家"),
    TaskItem(id: 9,  emoji: "🍳", timeRange: "17:00-18:00", name: "做晚饭",             detail: "自己做饭"),
    TaskItem(id: 10, emoji: "🍽️", timeRange: "18:00-19:00", name: "晚餐 + 休息",       detail: "饭后散步/放松"),
    TaskItem(id: 11, emoji: "💪", timeRange: "19:00-20:20", name: "力量训练+有氧35min", detail: "力量45分+有氧35分"),
    TaskItem(id: 12, emoji: "🛀", timeRange: "20:20-21:00", name: "洗漱放松",           detail: "复盘今日+规划明日"),
    TaskItem(id: 13, emoji: "😴", timeRange: "22:30-23:00", name: "睡觉",               detail: "保证7-8小时睡眠"),
]

let weekdays = ["周日","周一","周二","周三","周四","周五","周六"]

func isSaturday(_ date: Date = Date()) -> Bool {
    Calendar.current.component(.weekday, from: date) == 7
}

func todayKey() -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-M-d"; return f.string(from: Date())
}
