import SwiftUI
import WidgetKit

struct DueCountEntry: TimelineEntry {
    let date: Date
    let summary: TodaySummaryData
}

struct DueCountProvider: TimelineProvider {
    func placeholder(in context: Context) -> DueCountEntry {
        DueCountEntry(date: Date(), summary: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (DueCountEntry) -> Void) {
        completion(DueCountEntry(date: Date(), summary: WidgetStore.loadSummary()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DueCountEntry>) -> Void) {
        let entry = DueCountEntry(date: Date(), summary: WidgetStore.loadSummary())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct DueCountWidgetEntryView: View {
    let entry: DueCountEntry

    var body: some View {
        ZStack {
            Color.white

            VStack(alignment: .leading, spacing: 8) {
                Text("오늘 복습")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.72))

                Text("\(entry.summary.dueCount)개")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.black)

                Text("약 \(entry.summary.estMinutes)분")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black.opacity(0.78))

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Label("\(entry.summary.streak)", systemImage: "flame.fill")
                    Label("\(entry.summary.freezeLeft)", systemImage: "snowflake")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.black.opacity(0.82))
            }
            .padding(14)
        }
        .widgetURL(URL(string: "studyjlpt://review"))
    }
}

struct DueCountWidget: Widget {
    let kind: String = "DueCountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DueCountProvider()) { entry in
            DueCountWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘 복습")
        .description("남은 복습 카드와 예상 시간을 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
