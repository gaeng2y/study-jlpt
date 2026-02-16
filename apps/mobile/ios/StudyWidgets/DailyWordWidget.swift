import SwiftUI
import WidgetKit

struct DailyWordEntry: TimelineEntry {
    let date: Date
    let word: DailyWordData
}

struct DailyWordProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyWordEntry {
        DailyWordEntry(date: Date(), word: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyWordEntry) -> Void) {
        completion(DailyWordEntry(date: Date(), word: WidgetStore.loadDailyWord()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyWordEntry>) -> Void) {
        let entry = DailyWordEntry(date: Date(), word: WidgetStore.loadDailyWord())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct DailyWordWidgetEntryView: View {
    let entry: DailyWordEntry

    var body: some View {
        ZStack {
            Color.white

            VStack(alignment: .leading, spacing: 8) {
                Text("오늘의 단어 · \(entry.word.jlptLevel)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.72))

                Text(entry.word.jp)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)

                if !entry.word.reading.isEmpty {
                    Text(entry.word.reading)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black.opacity(0.78))
                        .lineLimit(1)
                }

                Text(entry.word.meaningKo)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.black.opacity(0.85))
                    .lineLimit(2)
            }
            .padding(14)
        }
        .widgetURL(URL(string: "studyjlpt://content/today-word"))
    }
}

struct DailyWordWidget: Widget {
    let kind: String = "DailyWordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyWordProvider()) { entry in
            DailyWordWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘의 단어")
        .description("일일 단어를 홈 화면에서 바로 확인합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
