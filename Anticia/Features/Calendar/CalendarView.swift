import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: [SortDescriptor(\CountdownEntity.targetDate, order: .forward)], animation: .snappy)
    private var events: [CountdownEntity]

    let now: Date
    let onAddTapped: () -> Void

    @State private var viewModel = CalendarViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker(String(localized: L10n.mode), selection: $viewModel.mode) {
                    ForEach(CalendarMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Button(String(localized: L10n.previousMonth), systemImage: "chevron.left") {
                        viewModel.moveMonth(by: -1)
                    }
                    .labelStyle(.iconOnly)

                    Spacer()

                    Text(viewModel.monthAnchor.monthAndYear)
                        .font(.title3.weight(.bold))

                    Spacer()

                    Button(String(localized: L10n.nextMonth), systemImage: "chevron.right") {
                        viewModel.moveMonth(by: 1)
                    }
                    .labelStyle(.iconOnly)
                }
                .padding(.horizontal, 4)

                if viewModel.mode == .month {
                    CalendarMonthView(
                        selectedDate: $viewModel.selectedDate,
                        month: viewModel.monthAnchor,
                        events: events,
                        now: now
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.title3.weight(.bold))

                        let selectedDayEvents = viewModel.eventsForSelectedDay(from: events, relativeTo: now)
                        if selectedDayEvents.isEmpty {
                            EmptyStateCard(
                                title: String(localized: L10n.calendarNoCountdownsTodayTitle),
                                subtitle: String(localized: L10n.calendarNoCountdownsTodaySubtitle)
                            )
                        } else {
                            ForEach(selectedDayEvents) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    EventRow(event: event, now: now)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        let visibleMonthEvents = viewModel.eventsForVisibleMonth(from: events, relativeTo: now)
                        if visibleMonthEvents.isEmpty {
                            EmptyStateCard(
                                title: String(localized: L10n.calendarNoCountdownsMonthTitle),
                                subtitle: String(localized: L10n.calendarNoCountdownsMonthSubtitle)
                            )
                        } else {
                            ForEach(visibleMonthEvents) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    EventRow(event: event, now: now)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
            .appPageWidth()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: L10n.calendar))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: L10n.addCountdown), systemImage: "plus", action: onAddTapped)
            }
        }
    }
}

private struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
