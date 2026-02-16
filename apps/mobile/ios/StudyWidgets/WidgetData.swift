import Foundation

struct TodaySummaryData {
    let dueCount: Int
    let newCount: Int
    let estMinutes: Int
    let streak: Int
    let freezeLeft: Int

    static let empty = TodaySummaryData(
        dueCount: 0,
        newCount: 0,
        estMinutes: 1,
        streak: 0,
        freezeLeft: 0
    )
}

struct DailyWordData {
    let jp: String
    let reading: String
    let meaningKo: String
    let jlptLevel: String

    static let empty = DailyWordData(
        jp: "단어 없음",
        reading: "",
        meaningKo: "앱에서 학습 데이터를 불러오면 표시됩니다.",
        jlptLevel: "N5"
    )
}

enum WidgetStore {
    static let appGroup = "group.co.gaeng2y.studyjlpt"
    static let summaryKey = "today_summary_json"
    static let dailyWordKey = "today_word_json"

    static func loadSummary() -> TodaySummaryData {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let raw = defaults.string(forKey: summaryKey),
            let data = raw.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return .empty
        }

        return TodaySummaryData(
            dueCount: json["dueCount"] as? Int ?? 0,
            newCount: json["newCount"] as? Int ?? 0,
            estMinutes: json["estMinutes"] as? Int ?? 1,
            streak: json["streak"] as? Int ?? 0,
            freezeLeft: json["freezeLeft"] as? Int ?? 0
        )
    }

    static func loadDailyWord() -> DailyWordData {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let raw = defaults.string(forKey: dailyWordKey),
            let data = raw.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return .empty
        }

        return DailyWordData(
            jp: json["jp"] as? String ?? "단어 없음",
            reading: json["reading"] as? String ?? "",
            meaningKo: json["meaningKo"] as? String ?? "",
            jlptLevel: json["jlptLevel"] as? String ?? "N5"
        )
    }
}
