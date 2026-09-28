import SwiftUI
import SwiftData

// MARK: - 记一笔 / 编辑账单
//
// 智能识别流程：
// 1. 备注输入时实时解析（「午饭25」→ 自动填金额 25，识别为餐饮）
// 2. 识别结果实时展示，分类胶囊横向滑动可改
// 3. 用户手动纠正 → 写入学习记忆（LearnedRule），越用越准
//
// Liquid Glass：
// - 分类胶囊用 GlassEffectContainer 包裹，玻璃间自动融合 morph
// - 选中胶囊 .regular.tint(分类色).interactive()

struct AddEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var learned: [LearnedRule]

    let editing: LedgerEntry?

    @State private var type: EntryType = .expense
    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var picked: Category?
    @State private var flash = false

    init(entry: LedgerEntry? = nil) {
        self.editing = entry
        if let e = entry {
            _type = State(initialValue: e.type)
            _amountText = State(initialValue: String(format: "%.2f", e.amount))
            _note = State(initialValue: e.title)
            _date = State(initialValue: e.date)
            _picked = State(initialValue: e.category)
        }
    }

    // 实时识别
    private var auto: Classifier.Result? {
        Classifier.classify(note, learned: learned)
    }

    private var selected: Category {
        if let picked { return picked }
        if let auto, Category.list(for: type).contains(auto.category) {
            return auto.category
        }
        return type == .expense ? .other : .otherIncome
    }

    private var amountIsValid: Bool {
        (Double(amountText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    typePicker
                    amountField
                    noteField
                    smartHint
                    dateRow
                    categoryChips
                    saveButton
                }
                .padding()
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(editing == nil ? "记一笔" : "编辑账单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: flash)
        }
    }

    // MARK: 类型切换（系统分段控件，iOS 26 自动玻璃化）

    private var typePicker: some View {
        Picker("类型", selection: $type) {
            Text("支出").tag(EntryType.expense)
            Text("收入").tag(EntryType.income)
        }
        .pickerStyle(.segmented)
        .onChange(of: type) { _, _ in
            picked = nil
        }
    }

    // MARK: 金额（液态玻璃输入卡）

    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("¥")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("0.00", text: $amountText)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    // MARK: 备注（智能解析入口）

    private var noteField: some View {
        TextField("备注，如：午餐、打车回家、工资到账", text: $note)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
            .onChange(of: note) { _, newValue in
                // 备注里写了金额且金额框为空 → 自动填入
                guard amountText.isEmpty else { return }
                let p = Classifier.parseAmount(in: newValue)
                guard let v = p.amount else { return }
                amountText = String(format: "%.2f", v)
                note = p.cleaned
            }
    }

    // MARK: 识别提示

    @ViewBuilder
    private var smartHint: some View {
        if !note.isEmpty {
            if let auto {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("已识别：\(auto.category.title)")
                        .font(.footnote.weight(.semibold))
                    if auto.learned {
                        Text("· 学习记忆")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("未识别，选个分类，我会记住你的偏好")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: 日期

    private var dateRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.footnote)
                .foregroundStyle(.secondary)
            DatePicker("日期", selection: $date, displayedComponents: .date)
                .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: .capsule)
    }

    // MARK: 分类胶囊（GlassEffectContainer 自动融合）

    private var categoryChips: some View {
        GlassEffectContainer(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Category.list(for: type)) { c in
                        let on = c == selected
                        Button { picked = c } label: {
                            Label(c.title, systemImage: c.symbol)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(on ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                        .glassEffect(
                            on ? .regular.tint(c.color).interactive() : .regular,
                            in: .capsule
                        )
                    }
                }
            }
        }
    }

    // MARK: 保存

    private var saveButton: some View {
        Button { save() } label: {
            Label("保存", systemImage: "checkmark")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.glassProminent)
        .tint(type.tint)
        .disabled(!amountIsValid)
    }

    private func save() {
        guard let amount = Double(amountText), amount > 0 else { return }
        let title = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let e = editing {
            e.typeRaw = type.rawValue
            e.categoryRaw = selected.rawValue
            e.title = title
            e.amount = amount
            e.date = date
        } else {
            context.insert(
                LedgerEntry(type: type, category: selected, title: title,
                            amount: amount, date: date)
            )
            // 学习：用户明确选择的分类与自动识别不同（或无识别）时记录偏好
            if let picked, !title.isEmpty {
                let differs = auto?.category != picked
                if differs {
                    learn(note: title, category: picked)
                }
            }
        }
        flash.toggle()
        dismiss()
    }

    private func learn(note: String, category: Category) {
        guard let kw = Classifier.keyword(from: note) else { return }
        let descriptor = FetchDescriptor<LearnedRule>(predicate: #Predicate { $0.keyword == kw })
        if let existing = try? context.fetch(descriptor).first {
            if existing.target == category {
                existing.count += 1
            } else {
                existing.category = category.rawValue
                existing.count = 1
            }
        } else {
            context.insert(LearnedRule(keyword: kw, category: category))
        }
    }
}

#Preview {
    AddEntryView()
        .modelContainer(for: [LedgerEntry.self, LearnedRule.self], inMemory: true)
}
