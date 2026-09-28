import SwiftUI
import SwiftData

// MARK: - 琉璃记账 · LiuliLedger
// iOS 26 · SwiftUI + SwiftData + Liquid Glass
// 部署目标：iOS 26（Liquid Glass API 最低要求）

@main
struct LiuliLedgerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            LedgerEntry.self,   // 账单
            LearnedRule.self,   // 学习记忆（分类偏好）
        ])
    }
}
