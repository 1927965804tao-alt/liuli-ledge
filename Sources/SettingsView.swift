import SwiftUI
import SwiftData

// MARK: - 我的
// 学习记忆管理 / CSV 导出（ShareLink 官方分享）/ 清空数据

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \LearnedRule.count, order: .reverse) private var rules: [LearnedRule]
    @Query private var entries: [LedgerEntry]

    @State private var confirmWipe = false

    var body: some View {
        NavigationStack {
            List {
                Section("数据概览") {
                    LabeledContent("累计账单", value: "\(entries.count) 笔")
                    LabeledContent("学习规则", value: "\(rules.count) 条")
                }

                Section {
                    if rules.isEmpty {
                        Text("暂无学习规则。\n记一笔并手动纠正分类，我就记住你的偏好。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(rules) { r in
                            HStack {
                                Text(r.keyword)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                if let c = r.target {
                                    Label(c.title, systemImage: c.symbol)
                                        .font(.footnote)
                                        .foregroundStyle(c.color)
                                }
                                Text("×\(r.count)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .onDelete(perform: deleteRules)
                    }
                } header: {
                    Text("智能学习记忆")
                } footer: {
                    Text("手动纠正分类时自动记录，优先级高于内置规则，越用越准。")
                }

                Section("备份") {
                    ShareLink(item: csvURL) {
                        Label("导出 CSV（Excel / Numbers 可打开）", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        confirmWipe = true
                    } label: {
                        Label("清空全部数据", systemImage: "trash")
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "1.0")
                    LabeledContent("设计材质", value: "Liquid Glass · iOS 26")
                    LabeledContent("数据存储", value: "SwiftData · 本机")
                }
            }
            .navigationTitle("我的")
            .confirmationDialog(
                "确认清空？",
                isPresented: $confirmWipe,
                titleVisibility: .visible
            ) {
                Button("清空全部数据", role: .destructive) { wipe() }
            } message: {
                Text("所有账单与学习规则将被删除，无法恢复。建议先导出 CSV 备份。")
            }
        }
    }

    private func deleteRules(at offsets: IndexSet) {
        for i in offsets {
            context.delete(rules[i])
        }
    }

    private func wipe() {
        try? context.delete(model: LedgerEntry.self)
        try? context.delete(model: LearnedRule.self)
    }

    // MARK: CSV 导出

    private var csvURL: URL {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        var lines = ["日期,类型,分类,备注,金额"]
        for e in entries.sorted(by: { $0.date < $1.date }) {
            let t = "\"" + e.title.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            lines.append([
                df.string(from: e.date),
                e.type.title,
                e.category.title,
                t,
                String(format: "%.2f", e.amount),
            ].joined(separator: ","))
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("琉璃记账导出.csv")
        let bom = "\u{FEFF}"   // Excel 中文兼容
        try? Data((bom + lines.joined(separator: "\n")).utf8).write(to: url)
        return url
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [LedgerEntry.self, LearnedRule.self], inMemory: true)
}
