import SwiftUI
import UIKit
import WidgetKit

struct AnticiaCountdownWidget: Widget {
    let kind = CountdownWidgetConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownTimelineProvider()) { entry in
            CountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Anticia")
        .description("Track your next countdown from the Home Screen or Lock Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

private struct CountdownTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownTimelineEntry {
        CountdownTimelineEntry(date: .now, snapshots: [.preview])
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownTimelineEntry) -> Void) {
        let now = Date()
        let entry = CountdownWidgetViewModel.snapshotEntry(date: now, snapshots: loadSnapshots())
        completion(preparingBackground(for: entry, in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownTimelineEntry>) -> Void) {
        let now = Date()
        let snapshots = loadSnapshots()
        let entry = preparingBackground(
            for: CountdownWidgetViewModel.timelineEntry(date: now, snapshots: snapshots), in: context
        )
        let nextRefresh = CountdownWidgetViewModel.nextRefreshDate(for: entry.snapshots, relativeTo: now)

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func preparingBackground(for entry: CountdownTimelineEntry, in context: Context) -> CountdownTimelineEntry {
        switch context.family {
        case .systemSmall, .systemMedium, .systemLarge:
            guard let snapshot = entry.snapshots.first else { return entry }
            let displayScale = context.environmentVariants.displayScale?.max() ?? 3
            return CountdownTimelineEntry(
                date: entry.date, snapshots: entry.snapshots,
                backgroundImage: CountdownImageStore.renderedBackground(
                    appearance: snapshot.appearance, size: context.displaySize, displayScale: displayScale
                )
            )
        default:
            return entry
        }
    }

    private func loadSnapshots() -> [CountdownWidgetSnapshot] {
        guard
            let defaults = UserDefaults(suiteName: CountdownWidgetConstants.appGroupIdentifier),
            let data = defaults.data(forKey: CountdownWidgetConstants.snapshotKey),
            let snapshots = try? JSONDecoder().decode([CountdownWidgetSnapshot].self, from: data)
        else { return [] }

        return snapshots
    }
}

struct CountdownTimelineEntry: TimelineEntry {
    let date: Date
    let snapshots: [CountdownWidgetSnapshot]
    var backgroundImage: UIImage? = nil
}

private struct CountdownWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: CountdownTimelineEntry

    var body: some View {
        let viewModel = CountdownWidgetViewModel(date: entry.date, snapshots: entry.snapshots)

        Group {
            switch family {
            case .systemSmall:
                SmallCountdownWidget(snapshot: viewModel.primarySnapshot, now: viewModel.date, backgroundImage: entry.backgroundImage)
            case .systemMedium:
                MediumCountdownWidget(snapshot: viewModel.primarySnapshot, now: viewModel.date, backgroundImage: entry.backgroundImage)
            case .systemLarge:
                LargeCountdownWidget(viewModel: viewModel, backgroundImage: entry.backgroundImage)
            case .accessoryCircular:
                CircularLockWidget(snapshot: viewModel.primarySnapshot, now: viewModel.date)
            case .accessoryRectangular:
                RectangularLockWidget(snapshot: viewModel.primarySnapshot, now: viewModel.date)
            case .accessoryInline:
                InlineLockWidget(snapshot: viewModel.primarySnapshot, now: viewModel.date)
            default:
                SmallCountdownWidget(snapshot: viewModel.primarySnapshot, now: viewModel.date, backgroundImage: entry.backgroundImage)
            }
        }
        .widgetURL(viewModel.widgetURL)
    }
}

private struct SmallCountdownWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsContainerBackground

    let snapshot: CountdownWidgetSnapshot?
    let now: Date
    let backgroundImage: UIImage?

    var body: some View {
        if let snapshot {
            let viewModel = CountdownSnapshotViewModel(snapshot: snapshot, now: now)
            let colors = WidgetAppearanceColors(
                appearance: snapshot.appearance,
                renderingMode: renderingMode,
                showsContainerBackground: showsContainerBackground
            )

            VStack(alignment: .leading, spacing: 8) {
                WidgetTitle(snapshot: snapshot, dateLine: viewModel.shortDateLine, colors: colors)

                Spacer(minLength: 6)

                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.daysRemainingText)
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                    Text("days to go")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(colors.primary)
            }
            .padding(16)
            .containerBackground(for: .widget) {
                WidgetCountdownBackground(theme: snapshot.theme, appearance: snapshot.appearance, image: backgroundImage)
            }
        } else {
            EmptyHomeWidget()
        }
    }
}

private struct MediumCountdownWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsContainerBackground

    let snapshot: CountdownWidgetSnapshot?
    let now: Date
    let backgroundImage: UIImage?

    var body: some View {
        if let snapshot {
            let viewModel = CountdownSnapshotViewModel(snapshot: snapshot, now: now)
            let colors = WidgetAppearanceColors(
                appearance: snapshot.appearance,
                renderingMode: renderingMode,
                showsContainerBackground: showsContainerBackground
            )

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    WidgetTitle(snapshot: snapshot, dateLine: viewModel.longDateLine, colors: colors)

                    Spacer(minLength: 6)

                    ProgressView(value: viewModel.progress)
                        .tint(colors.primary.opacity(0.8))
                }

                VStack(alignment: .trailing, spacing: 1) {
                    Text(viewModel.daysRemainingText)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                    Text("days")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(colors.primary)
            }
            .padding(18)
            .containerBackground(for: .widget) {
                WidgetCountdownBackground(theme: snapshot.theme, appearance: snapshot.appearance, image: backgroundImage)
            }
        } else {
            EmptyHomeWidget()
        }
    }
}

private struct LargeCountdownWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsContainerBackground

    let viewModel: CountdownWidgetViewModel
    let backgroundImage: UIImage?

    var body: some View {
        if let primarySnapshot = viewModel.primarySnapshot {
            let colors = WidgetAppearanceColors(
                appearance: primarySnapshot.appearance,
                renderingMode: renderingMode,
                showsContainerBackground: showsContainerBackground
            )

            VStack(alignment: .leading, spacing: 14) {
                Text("Upcoming")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(colors.primary)

                VStack(spacing: 10) {
                    ForEach(viewModel.largeWidgetSnapshots) { snapshot in
                        let snapshotViewModel = CountdownSnapshotViewModel(snapshot: snapshot, now: viewModel.date)

                        Link(destination: snapshot.deepLinkURL) {
                            HStack(spacing: 12) {
                                Image(systemName: snapshot.iconName)
                                    .font(.headline.weight(.bold))
                                    .frame(width: 32, height: 32)
                                    .background(colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snapshot.title)
                                        .font(.subheadline.weight(.bold))
                                        .lineLimit(1)
                                    Text(snapshotViewModel.shortDateLine)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(colors.secondary)
                                }

                                Spacer(minLength: 8)

                                Text(snapshotViewModel.statusLine)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(colors.primary.opacity(0.85))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(colors.primary)
                        }
                    }
                }
            }
            .padding(18)
            .containerBackground(for: .widget) {
                WidgetCountdownBackground(theme: primarySnapshot.theme, appearance: primarySnapshot.appearance, image: backgroundImage)
            }
        } else {
            EmptyHomeWidget()
        }
    }
}

private struct WidgetAppearanceColors {
    let primary: Color
    let secondary: Color

    init(appearance: CountdownAppearance, renderingMode: WidgetRenderingMode, showsContainerBackground: Bool) {
        if renderingMode == .fullColor && showsContainerBackground {
            primary = appearance.foregroundColor(default: .black.opacity(0.84))
            secondary = appearance.secondaryColor(default: .black.opacity(0.58))
        } else {
            primary = .primary
            secondary = .secondary
        }
    }
}

private struct WidgetCountdownBackground: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let theme: CountdownTheme
    let appearance: CountdownAppearance
    let image: UIImage?

    var body: some View {
        if renderingMode == .fullColor {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        Color.black.opacity(min(max(appearance.dimAmount.isFinite ? appearance.dimAmount : 0.25, 0), 0.8))
                    }
                    .clipped()
                    .accessibilityHidden(true)
            } else {
                theme.gradient
                    .overlay {
                        if appearance.hasImage { Color.black.opacity(0.35) }
                    }
            }
        } else {
            Color.clear
        }
    }
}

private struct CircularLockWidget: View {
    let snapshot: CountdownWidgetSnapshot?
    let now: Date

    var body: some View {
        if let snapshot {
            let viewModel = CountdownSnapshotViewModel(snapshot: snapshot, now: now)

            VStack(spacing: 0) {
                Text(viewModel.daysRemainingText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("days")
                    .font(.system(size: 10, weight: .semibold))
            }
            .widgetAccentable()
            .containerBackground(.clear, for: .widget)
        } else {
            Image(systemName: "calendar.badge.plus")
                .widgetAccentable()
                .containerBackground(.clear, for: .widget)
        }
    }
}

private struct RectangularLockWidget: View {
    let snapshot: CountdownWidgetSnapshot?
    let now: Date

    var body: some View {
        if let snapshot {
            let viewModel = CountdownSnapshotViewModel(snapshot: snapshot, now: now)

            VStack(alignment: .leading, spacing: 2) {
                Label(snapshot.title, systemImage: snapshot.iconName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                Text(viewModel.statusLine)
                    .font(.caption.weight(.semibold))
            }
            .widgetAccentable()
            .containerBackground(.clear, for: .widget)
        } else {
            Label("No countdowns", systemImage: "calendar.badge.plus")
                .widgetAccentable()
                .containerBackground(.clear, for: .widget)
        }
    }
}

private struct InlineLockWidget: View {
    let snapshot: CountdownWidgetSnapshot?
    let now: Date

    var body: some View {
        if let snapshot {
            let viewModel = CountdownSnapshotViewModel(snapshot: snapshot, now: now)

            Text("\(Image(systemName: snapshot.iconName)) \(snapshot.title) \(viewModel.statusLine)")
                .containerBackground(.clear, for: .widget)
        } else {
            Text("\(Image(systemName: "calendar.badge.plus")) No countdowns")
                .containerBackground(.clear, for: .widget)
        }
    }
}

private struct WidgetTitle: View {
    let snapshot: CountdownWidgetSnapshot
    let dateLine: String
    let colors: WidgetAppearanceColors

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label {
                Text(snapshot.title)
                    .lineLimit(1)
            } icon: {
                Image(systemName: snapshot.iconName)
            }
            .font(.headline.weight(.bold))

            Text(dateLine)
                .font(.caption.weight(.semibold))
                .foregroundStyle(colors.secondary)
                .lineLimit(1)
        }
        .foregroundStyle(colors.primary)
    }
}

private struct EmptyHomeWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.title2.weight(.semibold))
            Spacer()
            Text("No countdowns")
                .font(.headline.weight(.bold))
            Text("Add one in Anticia")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .containerBackground(.background, for: .widget)
    }
}

private enum CountdownWidgetConstants {
    static let appGroupIdentifier = "group.com.lancy.Anticia"
    static let snapshotKey = "countdownWidgetSnapshots"
    static let widgetKind = "AnticiaCountdownWidget"
}

struct CountdownWidgetSnapshot: Codable, Identifiable {
    let id: UUID
    let title: String
    let iconName: String
    let targetDate: Date
    let isAllDay: Bool
    let themeRawValue: String
    let repeatRuleRawValue: String
    let createdAt: Date
    let backgroundKindRawValue: String?
    let backgroundImageName: String?
    let textColorHex: String?
    let backgroundDimAmount: Double?
    let backgroundImageScale: Double?
    let backgroundImagePositionX: Double?
    let backgroundImagePositionY: Double?

    init(
        id: UUID,
        title: String,
        iconName: String,
        targetDate: Date,
        isAllDay: Bool,
        themeRawValue: String,
        repeatRuleRawValue: String,
        createdAt: Date,
        backgroundKindRawValue: String? = nil,
        backgroundImageName: String? = nil,
        textColorHex: String? = nil,
        backgroundDimAmount: Double? = nil,
        backgroundImageScale: Double? = nil,
        backgroundImagePositionX: Double? = nil,
        backgroundImagePositionY: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.targetDate = targetDate
        self.isAllDay = isAllDay
        self.themeRawValue = themeRawValue
        self.repeatRuleRawValue = repeatRuleRawValue
        self.createdAt = createdAt
        self.backgroundKindRawValue = backgroundKindRawValue
        self.backgroundImageName = backgroundImageName
        self.textColorHex = textColorHex
        self.backgroundDimAmount = backgroundDimAmount
        self.backgroundImageScale = backgroundImageScale
        self.backgroundImagePositionX = backgroundImagePositionX
        self.backgroundImagePositionY = backgroundImagePositionY
    }

    static let preview = CountdownWidgetSnapshot(
        id: UUID(),
        title: "Japan Trip",
        iconName: "airplane",
        targetDate: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now,
        isAllDay: true,
        themeRawValue: "ocean",
        repeatRuleRawValue: "never",
        createdAt: Calendar.current.date(byAdding: .day, value: -10, to: .now) ?? .now
    )

    var theme: CountdownTheme {
        CountdownTheme(rawValue: themeRawValue) ?? .ocean
    }

    var appearance: CountdownAppearance {
        CountdownAppearance(
            backgroundKind: CountdownBackgroundKind(rawValue: backgroundKindRawValue ?? "") ?? .gradient,
            imageName: backgroundImageName,
            textColorHex: textColorHex,
            dimAmount: backgroundDimAmount ?? 0.25,
            imageScale: backgroundImageScale ?? 1,
            imagePositionX: backgroundImagePositionX ?? 0.5,
            imagePositionY: backgroundImagePositionY ?? 0.5
        )
    }

    var repeatRule: CountdownRepeatRule {
        CountdownRepeatRule(rawValue: repeatRuleRawValue) ?? .never
    }

    var deepLinkURL: URL {
        URL(string: "anticia://countdown/\(id.uuidString)") ?? URL(string: "anticia://countdowns")!
    }

    func nextOccurrenceDate(relativeTo now: Date) -> Date {
        repeatRule.nextOccurrence(after: targetDate, relativeTo: now, isAllDay: isAllDay)
    }

    func expirationDate(relativeTo now: Date) -> Date {
        let occurrenceDate = nextOccurrenceDate(relativeTo: now)
        if isAllDay {
            let startOfDay = Calendar.current.startOfDay(for: occurrenceDate)
            return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? occurrenceDate
        }

        return occurrenceDate
    }

    func isExpired(relativeTo now: Date) -> Bool {
        !repeatRule.isRepeating && expirationDate(relativeTo: now) <= now
    }

    func daysRemaining(relativeTo now: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: nextOccurrenceDate(relativeTo: now))
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    func progress(relativeTo now: Date) -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: createdAt)
        let end = calendar.startOfDay(for: nextOccurrenceDate(relativeTo: now))
        let current = calendar.startOfDay(for: now)
        let total = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
        let elapsed = min(max(0, calendar.dateComponents([.day], from: start, to: current).day ?? 0), total)
        return Double(elapsed) / Double(total)
    }

    func statusLine(relativeTo now: Date) -> String {
        let days = daysRemaining(relativeTo: now)
        if days == 0 { return "today" }
        if days == 1 { return "tomorrow" }
        return "\(max(0, days)) days"
    }

    func dateLine(relativeTo now: Date, style: CountdownWidgetDateStyle) -> String {
        let date = nextOccurrenceDate(relativeTo: now)
        if isAllDay || style == .short {
            return date.formatted(.dateTime.month(.abbreviated).day().year())
        }

        return date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
    }
}

enum CountdownWidgetDateStyle {
    case short
    case long
}

enum CountdownRepeatRule: String {
    case never
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case yearly

    var isRepeating: Bool {
        self != .never
    }

    func nextOccurrence(
        after originalDate: Date,
        relativeTo now: Date,
        isAllDay: Bool,
        calendar: Calendar = .current
    ) -> Date {
        guard isRepeating else { return originalDate }

        let comparisonTarget = isAllDay ? calendar.startOfDay(for: now) : now
        let originalComparisonDate = isAllDay ? calendar.startOfDay(for: originalDate) : originalDate
        guard originalComparisonDate < comparisonTarget else { return originalDate }

        var intervalCount = estimatedIntervalCount(from: originalDate, to: now, calendar: calendar)
        var candidate = date(adding: intervalCount, to: originalDate, calendar: calendar)

        while (isAllDay ? calendar.startOfDay(for: candidate) : candidate) < comparisonTarget {
            intervalCount += 1
            candidate = date(adding: intervalCount, to: originalDate, calendar: calendar)
        }

        return candidate
    }

    private func estimatedIntervalCount(from originalDate: Date, to now: Date, calendar: Calendar) -> Int {
        let count: Int
        switch self {
        case .never:
            count = 0
        case .daily:
            count = calendar.dateComponents([.day], from: originalDate, to: now).day ?? 0
        case .weekly:
            count = (calendar.dateComponents([.day], from: originalDate, to: now).day ?? 0) / 7
        case .biweekly:
            count = (calendar.dateComponents([.day], from: originalDate, to: now).day ?? 0) / 14
        case .monthly:
            count = calendar.dateComponents([.month], from: originalDate, to: now).month ?? 0
        case .quarterly:
            count = (calendar.dateComponents([.month], from: originalDate, to: now).month ?? 0) / 3
        case .yearly:
            count = calendar.dateComponents([.year], from: originalDate, to: now).year ?? 0
        }

        return max(1, count)
    }

    private func date(adding intervalCount: Int, to originalDate: Date, calendar: Calendar) -> Date {
        switch self {
        case .never:
            return originalDate
        case .daily:
            return calendar.date(byAdding: .day, value: intervalCount, to: originalDate) ?? originalDate
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: intervalCount, to: originalDate) ?? originalDate
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: intervalCount * 2, to: originalDate) ?? originalDate
        case .monthly:
            return calendar.date(byAdding: .month, value: intervalCount, to: originalDate) ?? originalDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: intervalCount * 3, to: originalDate) ?? originalDate
        case .yearly:
            return calendar.date(byAdding: .year, value: intervalCount, to: originalDate) ?? originalDate
        }
    }
}

enum CountdownTheme: String {
    case ocean
    case sunset
    case candy
    case lavender
    case mint
    case peach

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var colors: [Color] {
        switch self {
        case .ocean:
            return [Color(hex: "5BC7F7"), Color(hex: "2F5DD6")]
        case .sunset:
            return [Color(hex: "FFB670"), Color(hex: "F06C5C")]
        case .candy:
            return [Color(hex: "FDB4C0"), Color(hex: "F37CA4")]
        case .lavender:
            return [Color(hex: "A5B4FF"), Color(hex: "7F72FF")]
        case .mint:
            return [Color(hex: "91F0D0"), Color(hex: "51C7A1")]
        case .peach:
            return [Color(hex: "FFD3A5"), Color(hex: "FFAA85")]
        }
    }
}
