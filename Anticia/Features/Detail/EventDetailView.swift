import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var isShowingDeletePrompt = false

    let event: CountdownEntity

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                hero
                details
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .appPageWidth()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(String(localized: L10n.edit)) {
                    isEditing = true
                }

                Button(String(localized: L10n.delete), systemImage: "trash", role: .destructive) {
                    isShowingDeletePrompt = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                EventEditorView(event: event)
            }
            .presentationDetents([.large])
        }
        .alert(String(localized: L10n.deleteCountdownPrompt), isPresented: $isShowingDeletePrompt) {
            Button(String(localized: L10n.delete), role: .destructive) {
                PersistenceController.delete(event, in: modelContext)
                dismiss()
            }
            Button(String(localized: L10n.cancel), role: .cancel) {}
        }
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(event.theme.gradient)
                .frame(height: 410)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 140, height: 140)
                        .padding(32)
                }

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(event.wrappedTitle)
                        .font(.title.weight(.bold))
                    Text(event.wrappedTargetDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.86))
                }
                .foregroundStyle(.white)

                    CountdownRing(
                        progress: event.countdownProgress,
                        primaryText: "\(max(0, abs(event.daysRemaining)))",
                        secondaryText: event.daysRemaining >= 0
                            ? String(localized: L10n.daysToGoShort)
                            : String(localized: L10n.daysAgoShort),
                        theme: event.theme
                    )

                HStack(spacing: 26) {
                    DetailMetric(
                        title: String(localized: L10n.dateMetric),
                        value: event.wrappedTargetDate.shortMonthDay
                    )
                    DetailMetric(title: String(localized: L10n.categoryMetric), value: event.category.title)
                    DetailMetric(
                        title: String(localized: L10n.statusMetric),
                        value: event.isFinished
                            ? String(localized: L10n.statusPast)
                            : String(localized: L10n.statusUpcoming)
                    )
                }
            }
            .padding(24)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.details)
                .font(.title3.weight(.bold))

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    DetailRow(
                        title: String(localized: L10n.dateMetric),
                        value: event.wrappedTargetDate.formatted(.dateTime.weekday(.wide).month().day().year())
                    )
                    DetailRow(
                        title: String(localized: L10n.time),
                        value: event.isAllDay ? String(localized: L10n.allDayValue) : event.wrappedTargetDate.timeLabel
                    )
                    DetailRow(title: String(localized: L10n.location), value: event.wrappedLocation)
                    DetailRow(title: String(localized: L10n.repeatRule), value: event.repeatRule.title)
                    DetailRow(title: String(localized: L10n.theme), value: event.theme.title)
                    DetailRow(title: String(localized: L10n.countdownMetric), value: event.statusCopy)
                }
            }
        }
    }

}

private struct DetailMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
