import SwiftUI
import WidgetKit

@main
struct StudyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DueCountWidget()
        DailyWordWidget()
    }
}
