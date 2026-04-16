import Foundation

@Observable
final class EventEditorViewModel {
    var title: String
    var category: CountdownCategory
    var targetDate: Date
    var location: String
    var notes: String
    var theme: CountdownTheme
    var iconName: String
    var isAllDay: Bool
    var repeatRule: CountdownRepeatRule
    var widgetStyle: CountdownWidgetStyle

    init(event: CountdownEntity?) {
        title = event?.wrappedTitle ?? ""
        category = event?.category ?? .travel
        targetDate = event?.originalTargetDate ?? .now
        location = event?.location ?? ""
        notes = event?.notes ?? ""
        theme = event?.theme ?? .ocean
        iconName = event?.wrappedIconName ?? CountdownCategory.travel.systemImage
        isAllDay = event?.isAllDay ?? true
        repeatRule = event?.repeatRule ?? .never
        widgetStyle = event?.widgetStyle ?? .classic
    }

    var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var draft: CountdownDraft {
        CountdownDraft(
            title: title,
            category: category,
            targetDate: targetDate,
            location: location,
            notes: notes,
            theme: theme,
            iconName: iconName,
            isAllDay: isAllDay,
            repeatRule: repeatRule,
            widgetStyle: widgetStyle
        )
    }

    func updateIconForCategory(_ newValue: CountdownCategory) {
        if iconName.isEmpty || CountdownCategory.allCases.map(\.systemImage).contains(iconName) {
            iconName = newValue.systemImage
        }
    }

    func validateIcon() {
        if !CountdownSymbolOption.allNames.contains(iconName) {
            iconName = category.systemImage
        }
    }
}
