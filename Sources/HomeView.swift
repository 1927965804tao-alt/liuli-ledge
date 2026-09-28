import SwiftUI
import SwiftData

// MARK: - 明细页
// 层级遵循官方 HIG：月概览为液态玻璃浮卡（.glassEffect），
// 账单列表用系统材质（.regularMaterial），内容沉稳不与玻璃争层级。

struct HomeView: View {
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]

    @State private var month = Date.now
    @State private var showAdd = false
    @State private var editing: LedgerEntry?

    private var calendar: Calendar { .current }

    private var monthEntries: [LedgerEntry] {
        entries.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    private var totalOut: Double {
        monthEntries.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var totalIn: Double {
        monthEntries.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var groups: [(day: Date, items: [LedgerEntry], out: Double)] {
        Dictionary(grouping: monthEntries) { calendar.startOfDay(for: $0.date) }
            .map { key, value in
                (day: key,
                 items: value.sorted { $0.createdAt > $1.createdAt },
                 out: value.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("琉璃记账")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.glassProminent)   // 官方液态玻璃主按钮
                }
            }
            .sheet(isPresented: $showAdd) { AddEntryView() }
            .sheet(item: $editing) { entry in AddEntryView(entry: entry) }
        }
    }

    // MARK: 列表

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                MonthSwitcher(month: $month)
                summaryCard
                ForEach(groups, id: \.day) { g in
                    daySection(g)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
        .contentMargins(.bottom, 24, for: .scrollContent)
    }

    // MARK: 月概览（液态玻璃）

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryColumn("本月支出", totalOut, big: true)
            Divider().frame(height: 36)
            summaryColumn("本月收入", totalIn)
            Divider().frame(height: 36)
            summaryColumn("结余", totalIn - totalOut, isBalance: true)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func summaryColumn(
        _ title: String, _ value: Double,
        big: Bool = false, isBalance: Bool = false
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "CNY").precision(.fractionLength(0...2)))
                .font(big ? .title2.bold() : .subheadline.bold())
                .foregroundStyle(
                    isBalance && value < 0 ? AnyShapeStyle(.orange) : AnyShapeStyle(.primary)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 按日分组

    private func daySection(_ g: (day: Date, items: [LedgerEntry], out: Double)) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(g.day, format: .dateTime.month().day().weekday(.narrow))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if g.out > 0 {
                    HStack(spacing: 3) {
                        Text("支出")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(g.out, format: .currency(code: "CNY").precision(.fractionLength(0...2)))
                            .font(.footnote.weight(.bold))
                            .monospacedDigit()
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)

            ForEach(Array(g.items.enumerated()), id: \.element.persistentModelID) { idx, e in
                entryRow(e)
                if idx < g.items.count - 1 {
                    Divider().padding(.leading, 64)
                }
            }
        }
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
    }

    private func entryRow(_ e: LedgerEntry) -> some View {
        Button { editing = e } label: {
            HStack(spacing: 12) {
                Image(systemName: e.category.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(e.category.color)
                    .frame(width: 38, height: 38)
                    .background(e.category.color.opacity(0.14), in: .rect(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.title.isEmpty ? e.category.title : e.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(e.category.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%@%.2f", e.type == .income ? "+" : "-", e.amount))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(
                        e.type == .income ? AnyShapeStyle(.green) : AnyShapeStyle(.primary)
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: 空状态

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有账单", systemImage: "square.and.pencil")
        } description: {
            Text("记下第一笔，琉璃会自动分类归纳。\n备注写得越自然，识别越准。")
        } actions: {
            Button("记一笔") { showAdd = true }
                .buttonStyle(.glassProminent)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [LedgerEntry.self, LearnedRule.self], inMemory: true)
}
