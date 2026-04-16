import SwiftUI
import SwiftData

struct UpcomingView: View {
    @Query(sort: [SortDescriptor(\CountdownEntity.targetDate, order: .forward)], animation: .snappy)
    private var events: [CountdownEntity]

    let now: Date
    let onAddTapped: () -> Void

    @AppStorage("userDisplayName") private var userDisplayName = ""
    @State private var viewModel = UpcomingViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                eventList
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
            .appPageWidth()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: L10n.upcoming))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: L10n.addCountdown), systemImage: "plus", action: onAddTapped)
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        let greeting = viewModel.greeting(name: userDisplayName)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(greeting.message)
                    .font(.title3.weight(.bold))
                Image(systemName: greeting.iconName)
                    .font(.subheadline.weight(.semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(greeting.primaryIconColor, greeting.secondaryIconColor)
            }

            Text(viewModel.countdownSummary(for: events, relativeTo: now))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var eventList: some View {
        let upcomingEvents = viewModel.upcomingEvents(from: events, relativeTo: now)

        if upcomingEvents.isEmpty {
            UpcomingEmptyState(onAddTapped: onAddTapped)
                .padding(.top, 72)
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.layoutSections(for: events, relativeTo: now)) { section in
                    switch section {
                    case .single(let event):
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            SimpleCountdownCard(event: event, style: event.widgetStyle, now: now)
                        }
                        .buttonStyle(.plain)

                    case .grid(let events):
                        LazyVGrid(columns: viewModel.gridColumns, spacing: 12) {
                            ForEach(events) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    SimpleCountdownCard(event: event, style: .grid, now: now)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct UpcomingEmptyState: View {
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color(hex: "2E6CF6"))
                .frame(width: 82, height: 82)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                )

            VStack(spacing: 7) {
                Text(L10n.upcomingEmptyTitle)
                    .font(.title3.weight(.bold))

                Text(L10n.upcomingEmptySubtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 260)
            }

            Button(action: onAddTapped) {
                    Label(String(localized: L10n.addCountdownLowercase), systemImage: "plus")
                    .font(.subheadline.weight(.bold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
    }
}
