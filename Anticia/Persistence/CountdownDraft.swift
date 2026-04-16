import Foundation

struct CountdownDraft {
    let title: String
    let category: CountdownCategory
    let targetDate: Date
    let location: String
    let notes: String
    let theme: CountdownTheme
    let iconName: String
    let isAllDay: Bool
    let repeatRule: CountdownRepeatRule
    let widgetStyle: CountdownWidgetStyle
}
