import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: [SortDescriptor(\CountdownEntity.targetDate, order: .forward)], animation: .snappy)
    private var events: [CountdownEntity]

    let now: Date
    let onAddTapped: () -> Void

    @State private var viewModel = TimelineViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker(String(localized: L10n.timeline), selection: $viewModel.segment) {
                    ForEach(TimelineSegment.allCases) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(.segmented)

                timelineContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
            .appPageWidth()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: L10n.timeline))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: L10n.addCountdown), systemImage: "plus", action: onAddTapped)
            }
        }
    }

    @ViewBuilder
    private var timelineContent: some View {
        let groupedEvents = viewModel.groupedEvents(from: events, relativeTo: now)

        if groupedEvents.isEmpty {
            TimelineEmptyState(segment: viewModel.segment, onAddTapped: onAddTapped)
                .padding(.top, 84)
        } else {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(groupedEvents, id: \.0) { month, monthEvents in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(month.monthAndYear)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.secondary)

                        ForEach(monthEvents) { event in
                            NavigationLink {
                                EventDetailView(event: event)
                            } label: {
                                TimelineRow(event: event, now: now)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct TimelineEmptyState: View {
    let segment: TimelineSegment
    let onAddTapped: () -> Void

    private var iconName: String {
        switch segment {
        case .upcoming:
            return "calendar.badge.plus"
        case .past:
            return "clock.arrow.circlepath"
        }
    }

    private var title: String {
        switch segment {
        case .upcoming:
            return String(localized: L10n.timelineNoUpcomingTitle)
        case .past:
            return String(localized: L10n.timelineNoPastTitle)
        }
    }

    private var subtitle: String {
        switch segment {
        case .upcoming:
            return String(localized: L10n.timelineNoUpcomingSubtitle)
        case .past:
            return String(localized: L10n.timelineNoPastSubtitle)
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: iconName)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color(hex: "2E6CF6"))
                .frame(width: 82, height: 82)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                )

            VStack(spacing: 7) {
                Text(title)
                    .font(.title3.weight(.bold))

                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 270)
            }

            if segment == .upcoming {
                Button(action: onAddTapped) {
                    Label(String(localized: L10n.addCountdownLowercase), systemImage: "plus")
                        .font(.subheadline.weight(.bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
    }
}

private struct TimelineRow: View {
    let event: CountdownEntity
    let now: Date

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(event.theme.tintColor)
                    .frame(width: 14, height: 14)

                Rectangle()
                    .fill(event.theme.tintColor.opacity(0.25))
                    .frame(width: 2, height: 76)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(event.nextOccurrenceDate(relativeTo: now).shortMonthDay)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(event.wrappedTitle)
                    .font(.headline)
                Text(event.wrappedNotes.isEmpty ? event.statusCopy(relativeTo: now) : event.wrappedNotes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}
