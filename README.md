# 琉璃记账 · LiuliLedger（iOS 原生版）

基于 **Apple 官方工具栈** 打造的 iPhone 记账 App，全面适配 **iOS 26 Liquid Glass** 设计语言。

## 🚫 没有 Mac？三条免费路径

| 路径 | 条件 | 说明 |
|---|---|---|
| **B. 云端编译（当前选定）** | 仅 Windows + iPhone | GitHub Actions 免费云端 Mac 编译 ipa → Windows 上 Sideloadly 签名安装。**详见 [CloudBuild/README.md](CloudBuild/README.md)** |
| A. iPad + Swift Playgrounds | 有任意 iPad | 双击打开 `LiuliLedger.swiftpm` 文件夹即可编辑运行，Apple 官方支持 |
| C. 学校/借 Mac | 有 Mac 可用 | 按「组装步骤」在 Xcode 26 里 5 分钟完成，体验最好 |

> 注意：无论哪条路径，iPhone 都需要升级到 **iOS 26** 才能运行（Liquid Glass API 要求）。

## 技术栈（全部为 Apple 官方框架）

| 能力 | 官方技术 |
|---|---|
| 界面框架 | SwiftUI |
| 液态玻璃 | Liquid Glass API：`.glassEffect()`、`.buttonStyle(.glass / .glassProminent)`、`GlassEffectContainer`、`.regular.tint().interactive()` |
| 数据记忆 | SwiftData（`@Model` / `@Query` / `FetchDescriptor`） |
| 统计图表 | Swift Charts（`SectorMark` 环形图 / `BarMark` 趋势图） |
| 触觉反馈 | `sensoryFeedback` |
| 系统组件 | `TabView`（iOS 26 原生玻璃浮动 Tab 栏）、`ContentUnavailableView`、`ShareLink`、`confirmationDialog`、`LabeledContent` |

## 功能

- ✍️ **记一笔**：备注智能解析（「午饭25」自动拆出金额）、实时分类识别、金额/日期/收支类型
- 🧠 **自动识别 + 学习进化**：内置 ~200 个中文关键词规则库；手动纠正分类会写入 `LearnedRule`，下次自动应用（可在「我的」页查看/删除学习规则）
- 📋 **明细**：月度收支概览（液态玻璃浮卡）、按日分组账单、点击编辑
- 📊 **统计**：分类占比环形图、每日支出趋势、收入来源、月份切换
- 🔒 **记忆功能**：SwiftData 本机持久化，CSV 导出备份（ShareLink 系统分享）

## 环境要求

- **Mac**（必须，Windows 无法编译 iOS 应用）
- **Xcode 26**（App Store 免费下载；Liquid Glass API 需要 iOS 26 SDK）
- iPhone 真机需升级到 **iOS 26**；无真机时可用内置模拟器（iOS 26）
- 免费 Apple ID 即可真机调试（签名 7 天有效，过期重新运行即可）；发布 App Store 需 Apple Developer Program（$99/年）

## 组装步骤（约 5 分钟）

1. 打开 **Xcode 26** → `File > New > Project > iOS > App`
2. 配置：
   - Product Name：`LiuliLedger`
   - Interface：**SwiftUI**
   - Language：**Swift**
   - Storage：**None**（SwiftData 由代码配置）
   - 勾选 Include Tests：**不勾**
3. 创建后，在项目导航器中**删除**自带的 `ContentView.swift`
4. 把本目录 `Sources/` 下的 **7 个 .swift 文件**全部拖入项目（勾选 `Copy items if needed`，Target 勾选 `LiuliLedger`）
5. 选中工程 → `Signing & Capabilities` → Team 选择你的 Apple ID（个人团队）
6. 顶部选择 iPhone 模拟器（iOS 26）或你的 iPhone → `Cmd + R` 运行

## 液态玻璃在哪里体现

| 位置 | 官方 API |
|---|---|
| 底部 Tab 栏 | `TabView` + `Tab`，iOS 26 系统自动液态玻璃浮动样式 |
| 月概览卡 / 金额输入卡 | `.glassEffect(.regular, in: .rect(cornerRadius: 24))` |
| 顶栏 + 记账按钮 | `.buttonStyle(.glassProminent)`，滚动时自动边缘高光 |
| 月份切换箭头 | `.buttonStyle(.glass)` |
| 分类胶囊 | `GlassEffectContainer` 包裹，相邻玻璃自动融合；选中态 `.regular.tint(分类色).interactive()` |
| 记账面板 | 系统 Sheet，iOS 26 自动玻璃化边缘与工具栏 |

## 目录结构

```
Sources/
├── LiuliLedgerApp.swift   入口 + SwiftData 容器
├── Models.swift           数据模型 / 分类定义 / 规则库 / 分类引擎 / 智能解析
├── ContentView.swift      TabView 根视图 + 月份切换组件
├── HomeView.swift         明细页（概览浮卡 + 按日分组账单）
├── AddEntryView.swift     记账面板（智能识别 + 学习记忆）
├── StatsView.swift        统计页（Swift Charts）
└── SettingsView.swift     设置页（规则管理 / 导出 / 清空）
```

## App 图标（可选）

Xcode 中 `Assets.xcassets > AppIcon`，拖入 1024×1024 图标即可。建议配色：蓝紫渐变 + 🫧 气泡元素，贴合 Liquid Glass 透明质感。
