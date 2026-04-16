import SwiftUI

struct EventRow: View {
    let event: CountdownEntity
    let now: Date

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(event.theme.gradient)
                    .frame(width: 52, height: 52)

                Image(systemName: event.wrappedIconName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(event.wrappedTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text(event.nextOccurrenceDate(relativeTo: now).shortMonthDay)
                    Text("•")
                    Text(event.statusCopy(relativeTo: now))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(event.category.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(event.theme.tintColor)
                Text(event.wrappedLocation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
        )
    }
}
