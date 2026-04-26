import Foundation
import SwiftData

enum PersistenceController {
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([CountdownEntity.self])
        let configuration = ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData container: \(error.localizedDescription)")
        }
    }()

    static func save(
        event: CountdownEntity?,
        draft: CountdownDraft,
        in context: ModelContext
    ) -> CountdownEntity {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIconName = draft.iconName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedIcon = trimmedIconName.isEmpty ? draft.category.systemImage : trimmedIconName
        let savedEvent: CountdownEntity

        if let event {
            event.title = trimmedTitle
            event.categoryRawValue = draft.category.rawValue
            event.repeatRuleRawValue = draft.repeatRule.rawValue
            event.targetDate = draft.targetDate
            event.location = trimmedLocation
            event.notes = trimmedNotes
            event.themeRawValue = draft.theme.rawValue
            event.iconName = resolvedIcon
            event.isAllDay = draft.isAllDay
            event.widgetStyleRawValue = draft.widgetStyle.rawValue
            if draft.repeatRule.isRepeating || !event.hasPassed() {
                event.isCompleted = false
            }
            savedEvent = event
        } else {
            let newEvent = CountdownEntity(
                iconName: resolvedIcon,
                isAllDay: draft.isAllDay,
                isCompleted: false,
                location: trimmedLocation,
                notes: trimmedNotes,
                categoryRawValue: draft.category.rawValue,
                repeatRuleRawValue: draft.repeatRule.rawValue,
                targetDate: draft.targetDate,
                themeRawValue: draft.theme.rawValue,
                title: trimmedTitle,
                widgetStyleRawValue: draft.widgetStyle.rawValue
            )
            context.insert(newEvent)
            savedEvent = newEvent
        }

        try? context.save()
        CountdownWidgetSnapshotStore.exportSnapshots(from: context)
        return savedEvent
    }

    static func completeExpiredEvents(in context: ModelContext, now: Date = .now) {
        let descriptor = FetchDescriptor<CountdownEntity>()
        guard let events = try? context.fetch(descriptor) else { return }

        var didUpdate = false
        for event in events
        where !event.isCompleted && !event.repeatRule.isRepeating && event.hasPassed(relativeTo: now) {
            event.isCompleted = true
            didUpdate = true
        }

        if didUpdate {
            try? context.save()
            CountdownWidgetSnapshotStore.exportSnapshots(from: context, now: now)
        }
    }

    static func mark(_ event: CountdownEntity, completed: Bool, in context: ModelContext) {
        event.isCompleted = completed
        try? context.save()
        CountdownWidgetSnapshotStore.exportSnapshots(from: context)

        if completed {
            CountdownNotificationScheduler.cancelStartNotification(for: event.wrappedID)
        } else {
            Task {
                await CountdownNotificationScheduler.scheduleStartNotification(for: event)
            }
        }
    }

    static func delete(_ event: CountdownEntity, in context: ModelContext) {
        CountdownNotificationScheduler.cancelStartNotification(for: event.wrappedID)
        context.delete(event)
        try? context.save()
        CountdownWidgetSnapshotStore.exportSnapshots(from: context)
    }
}
