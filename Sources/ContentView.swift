import SwiftUI

// MARK: - 根视图
// iOS 26 的 TabView 原生就是液态玻璃浮动 Tab 栏，无需自定义

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("明细", systemImage: "list.bullet.rectangle.fill") {
                HomeView()
            }
            Tab("统计", systemImage: "chart.pie.fill") {
                StatsView()
            }
            Tab("我的", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

// MARK: - 月份切换器（明细 / 统计共用）
// 官方 Liquid Glass：.buttonStyle(.glass)

struct MonthSwitcher: View {
    @Binding var month: Date

    var body: some View {
        HStack(spacing: 10) {
            Button { shift(-1) } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.glass)

            Text(month, format: .dateTime.year().month())
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .frame(minWidth: 96)

            Button { shift(1) } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity)
    }

    private func shift(_ n: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: n, to: month) {
            month = d
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [LedgerEntry.self, LearnedRule.self], inMemory: true)
}
