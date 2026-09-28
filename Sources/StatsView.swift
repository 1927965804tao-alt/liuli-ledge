import SwiftUI
import SwiftData
import Charts

// MARK: - 统计页
// Swift Charts 官方框架：SectorMark 环形图（支出构成）+ BarMark 每日趋势

struct StatsView: View {
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]

    @State private var month = Date.now

    private var calendar: Calendar { .current }

    private var monthEntries: [LedgerEntry] {
        entries.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
    }
    private var outEntries: [LedgerEntry] {
        monthEntries.filter { $0.type == .expense }
    }
    private var totalOut: Double {
        outEntries.reduce(0) { $0 + $1.amount }
    }
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: month)?.count ?? 30
    }

    private var byCategory: [(cat: Category, total: Double)] {
        Dictionary(grouping: outEntries) { $0.category }
            .map { (cat: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    private var daily: [(day: Date, total: Double)] {
        Dictionary(grouping: outEntries) { calendar.startOfDay(for: $0.date) }
            .map { (day: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.day < $1.day }
    }

    private var incomeByCategory: [(cat: Category, total: Double)] {
        Dictionary(grouping: monthEntries.filter { $0.type == .income }) { $0.category }
            .map { (cat: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    MonthSwitcher(month: $month)
                    if monthEntries.isEmpty {
                        ContentUnavailableView(
                            "本月暂无数据",
                            systemImage: "chart.pie",
                            description: Text("记几笔账，图表立刻出现")
                        )
                    } else {
                        donutCard
                        trendCard
                        if !incomeByCategory.isEmpty {
                            incomeCard
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("统计")
        }
    }

    // MARK: 支出构成（环形图 + 图例）

    private var donutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("支出构成", systemImage: "circle.circle")
                .font(.headline)

            Chart(byCategory, id: \.cat) { item in
                SectorMark(
                    angle: .value("金额", item.total),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .foregroundStyle(item.cat.color)
                .cornerRadius(4)
            }
            .chartBackground { _ in
                VStack(spacing: 2) {
                    Text("本月支出")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalOut, format: .currency(code: "CNY").precision(.fractionLength(0...2)))
                        .font(.title3.bold())
                        .monospacedDigit()
                }
            }
            .frame(height: 190)
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(byCategory.prefix(7), id: \.cat) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.cat.color)
                            .frame(width: 9, height: 9)
                        Text(item.cat.title)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(item.total, format: .currency(code: "CNY").precision(.fractionLength(0...2)))
                            .font(.footnote.weight(.semibold))
                            .monospacedDigit()
                        Text("\(Int(item.total / max(totalOut, 0.01) * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 34, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 22))
    }

    // MARK: 每日趋势

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("每日支出", systemImage: "chart.bar.fill")
                .font(.headline)

            Chart(daily, id: \.day) { item in
                BarMark(
                    x: .value("日期", item.day, unit: .day),
                    y: .value("支出", item.total),
                    width: .ratio(0.62)
                )
                .foregroundStyle(.tint.gradient)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) {
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 140)

            Text("日均 ¥\(String(format: "%.0f", totalOut / Double(max(daysInMonth, 1))))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 22))
    }

    // MARK: 收入来源

    private var incomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("收入来源", systemImage: "banknote.fill")
                .font(.headline)

            ForEach(incomeByCategory, id: \.cat) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.cat.symbol)
                        .foregroundStyle(item.cat.color)
                        .frame(width: 30)
                    Text(item.cat.title)
                        .font(.subheadline)
                    Spacer()
                    Text("+\(String(format: "%.2f", item.total))")
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 22))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [LedgerEntry.self, LearnedRule.self], inMemory: true)
}
