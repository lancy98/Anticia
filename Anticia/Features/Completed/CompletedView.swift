import SwiftUI
import SwiftData

struct CompletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CountdownEntity.targetDate, order: .reverse)], animation: .snappy)
    private var events: [CountdownEntity]

    let now: Date
    let onAddTapped: () -> Void
    @State private var viewModel = CompletedViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                let completedEvents = viewModel.completedEvents(from: events, relativeTo: now)
                if completedEvents.isEmpty {
                    CompletedEmptyState()
                        .padding(.top, 72)
                } else {
                    VStack(spacing: 12) {
                        ForEach(completedEvents) { event in
                            NavigationLink {
                                EventDetailView(event: event)
                            } label: {
                                EventRow(event: event, now: now)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    PersistenceController.delete(event, in: modelContext)
                                } label: {
                                    Label(String(localized: L10n.delete), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 120)
            .appPageWidth()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: L10n.completed))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: L10n.addCountdown), systemImage: "plus", action: onAddTapped)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.completed)
                .font(.title3.weight(.bold))

            Text(viewModel.completedSummary(for: events, relativeTo: now))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
}

private struct CompletedEmptyState: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color(hex: "1F9D55"))
                .frame(width: 82, height: 82)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                )

            VStack(spacing: 7) {
                Text(L10n.completedEmptyTitle)
                    .font(.title3.weight(.bold))

                Text(L10n.completedEmptySubtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 270)
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
    }
}
