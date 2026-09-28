import Foundation
import SwiftData
import SwiftUI

// MARK: - 账单类型

enum EntryType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }
    var title: String { self == .expense ? "支出" : "收入" }
    var tint: Color { self == .expense ? .orange : .green }
}

// MARK: - 分类

enum Category: String, Codable, CaseIterable, Identifiable {
    case dining, transport, shopping, fun, housing, health, education, social, pet, other
    case salary, sideJob, invest, redPacket, reimburse, otherIncome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dining: "餐饮"
        case .transport: "交通"
        case .shopping: "购物"
        case .fun: "娱乐"
        case .housing: "居住"
        case .health: "医疗"
        case .education: "教育"
        case .social: "人情"
        case .pet: "宠物"
        case .other: "其他"
        case .salary: "工资"
        case .sideJob: "兼职"
        case .invest: "理财"
        case .redPacket: "红包"
        case .reimburse: "报销"
        case .otherIncome: "其他收入"
        }
    }

    var symbol: String {
        switch self {
        case .dining: "fork.knife"
        case .transport: "car.fill"
        case .shopping: "bag.fill"
        case .fun: "gamecontroller.fill"
        case .housing: "house.fill"
        case .health: "pills.fill"
        case .education: "book.fill"
        case .social: "gift.fill"
        case .pet: "cat.fill"
        case .other: "square.grid.2x2"
        case .salary: "banknote.fill"
        case .sideJob: "briefcase.fill"
        case .invest: "chart.line.uptrend.xyaxis"
        case .redPacket: "envelope.open.fill"
        case .reimburse: "doc.text.fill"
        case .otherIncome: "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .dining: .orange
        case .transport: .cyan
        case .shopping: .pink
        case .fun: .purple
        case .housing: .blue
        case .health: .green
        case .education: .yellow
        case .social: .red
        case .pet: .mint
        case .other: .gray
        case .salary: .green
        case .sideJob: .indigo
        case .invest: .teal
        case .redPacket: .red
        case .reimburse: .purple
        case .otherIncome: .gray
        }
    }

    static func list(for type: EntryType) -> [Category] {
        type == .expense
        ? [.dining, .transport, .shopping, .fun, .housing, .health, .education, .social, .pet, .other]
        : [.salary, .sideJob, .invest, .redPacket, .reimburse, .otherIncome]
    }
}

// MARK: - SwiftData 模型

@Model
final class LedgerEntry {
    var typeRaw: String
    var categoryRaw: String
    var title: String
    var amount: Double
    var date: Date
    var createdAt: Date

    init(type: EntryType, category: Category, title: String, amount: Double, date: Date = .now) {
        self.typeRaw = type.rawValue
        self.categoryRaw = category.rawValue
        self.title = title
        self.amount = amount
        self.date = date
        self.createdAt = .now
    }

    var type: EntryType { EntryType(rawValue: typeRaw) ?? .expense }
    var category: Category { Category(rawValue: categoryRaw) ?? .other }
}

/// 学习记忆：用户手动纠正分类时记录「关键词 → 分类」偏好
@Model
final class LearnedRule {
    @Attribute(.unique) var keyword: String
    var category: String
    var count: Int

    init(keyword: String, category: Category) {
        self.keyword = keyword
        self.category = category.rawValue
        self.count = 1
    }

    var target: Category? { Category(rawValue: category) }
}

// MARK: - 智能分类引擎
// 内置关键词规则库 + 用户学习记忆（优先级更高，按学习次数加权）

struct CategoryRule {
    let category: Category
    let keywords: [String]
}

enum Classifier {

    struct Result: Equatable {
        let category: Category
        let learned: Bool
    }

    static let builtIn: [CategoryRule] = [
        .init(category: .dining, keywords: [
            "餐", "饭", "外卖", "美团", "饿了么", "肯德基", "麦当劳", "星巴克", "瑞幸",
            "咖啡", "奶茶", "喜茶", "蜜雪", "米线", "米粉", "火锅", "烧烤", "早餐",
            "午餐", "晚餐", "夜宵", "小吃", "食堂", "拉面", "饺子", "包子", "豆浆",
            "油条", "披萨", "汉堡", "寿司", "烤肉", "零食", "面包", "蛋糕", "甜品",
        ]),
        .init(category: .transport, keywords: [
            "地铁", "公交", "打车", "滴滴", "出租", "高铁", "火车", "机票", "飞机",
            "加油", "汽油", "停车", "过路", "单车", "哈啰", "摩托", "电动车", "充电桩",
        ]),
        .init(category: .shopping, keywords: [
            "淘宝", "京东", "拼多多", "天猫", "唯品会", "超市", "便利", "衣服", "鞋",
            "裤子", "外套", "化妆品", "口红", "护肤", "洗发", "纸巾", "洗衣", "家居", "日用", "杂货",
        ]),
        .init(category: .fun, keywords: [
            "电影", "游戏", "音乐", "ktv", "旅游", "门票", "会员", "爱奇艺", "优酷",
            "原神", "王者荣耀", "演出", "演唱会", "健身", "游泳", "剧本杀", "桌游",
        ]),
        .init(category: .housing, keywords: [
            "房租", "水电", "物业", "燃气", "宽带", "话费", "电费", "水费", "网费",
            "暖气", "家具", "家电", "维修", "装修",
        ]),
        .init(category: .health, keywords: [
            "药", "医院", "门诊", "挂号", "体检", "牙", "眼科", "疫苗", "看病", "诊所", "保健品",
        ]),
        .init(category: .education, keywords: [
            "书", "学费", "课程", "培训", "考试", "报名", "网课", "打印", "文具", "教材", "考研", "考证",
        ]),
        .init(category: .social, keywords: [
            "红包", "礼物", "生日", "婚礼", "份子", "随礼", "探望", "捐赠", "请客",
        ]),
        .init(category: .pet, keywords: ["猫粮", "狗粮", "宠物", "驱虫"]),
        .init(category: .salary, keywords: ["工资", "薪资", "薪水", "奖金", "年终奖", "绩效"]),
        .init(category: .sideJob, keywords: ["兼职", "外快", "私活", "稿费", "报酬"]),
        .init(category: .invest, keywords: ["利息", "分红", "基金", "股票", "收益", "理财"]),
        .init(category: .redPacket, keywords: ["压岁钱", "收红包"]),
        .init(category: .reimburse, keywords: ["报销", "退款", "返现"]),
    ]

    /// 分类：学习记忆优先（按次数降序），其次内置规则
    static func classify(_ text: String, learned: [LearnedRule]) -> Result? {
        let t = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }

        for rule in learned.sorted(by: { $0.count > $1.count })
        where t.contains(rule.keyword.lowercased()) {
            if let c = Category(rawValue: rule.category) {
                return Result(category: c, learned: true)
            }
        }
        for rule in builtIn where rule.keywords.contains(where: { t.contains($0.lowercased()) }) {
            return Result(category: rule.category, learned: false)
        }
        return nil
    }

    // MARK: 备注智能解析（自动提取金额）

    struct SmartParse {
        let amount: Double?
        let cleaned: String
    }

    /// 「午饭25」→ 25 + 午饭；「奶茶15x2」→ 30 + 奶茶
    static func parseAmount(in raw: String) -> SmartParse {
        var s = raw

        if let m = s.firstMatch(of: /(\d+(?:\.\d{1,2})?)\s*[xX×*]\s*(\d+(?:\.\d{1,2})?)/) {
            let v = ((Double(m.1) ?? 0) * (Double(m.2) ?? 0) * 100).rounded() / 100
            s = s.replacing(m.0, with: " ")
            return SmartParse(amount: v > 0 ? v : nil, cleaned: tidy(s))
        }
        if let m = s.firstMatch(of: /(\d+(?:\.\d{1,2})?)/) {
            let v = Double(m.1) ?? 0
            s = s.replacing(m.0, with: " ")
            return SmartParse(amount: v > 0 ? v : nil, cleaned: tidy(s))
        }
        return SmartParse(amount: nil, cleaned: tidy(s))
    }

    /// 从备注提取学习关键词（去掉数字、单位、空白）
    static func keyword(from note: String) -> String? {
        let key = note
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.元块圆xX×* "))
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        return String(key.prefix(12))
    }

    private static func tidy(_ s: String) -> String {
        s.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
