import SwiftUI

struct SimpleCountdownCard: View {
    let event: CountdownEntity
    let style: CountdownWidgetStyle
    let now: Date

    @ViewBuilder
    var body: some View {
        switch style {
        case .classic:
            classicCard
        case .compact:
            compactCard
        case .grid:
            gridCard
        }
    }

    private var classicCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            titleBlock(color: primaryTextColor, secondaryColor: secondaryTextColor)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(max(0, event.daysRemaining(relativeTo: now)))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.daysLabel)
                        .font(.caption.weight(.bold))
                    Text(L10n.toGoLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(secondaryTextColor)
                }
            }
            .foregroundStyle(primaryTextColor)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(event.theme.gradient)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 110, height: 110)
                        .offset(x: 34, y: -34)
                }
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 18)
                        .frame(width: 96, height: 96)
                        .offset(x: 28, y: 32)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.42), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: event.theme.tintColor.opacity(0.18), radius: 14, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var compactCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 54, height: 54)

                Image(systemName: event.wrappedIconName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryTextColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(event.wrappedTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryTextColor)
                    .lineLimit(1)

                Text(dateLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(max(0, event.daysRemaining(relativeTo: now)))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                Text(L10n.daysLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(.trailing, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(event.theme.gradient)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 96, height: 96)
                        .offset(x: 28, y: -42)
                }
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 16)
                        .frame(width: 78, height: 78)
                        .offset(x: 24, y: 32)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.42), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: event.theme.tintColor.opacity(0.18), radius: 14, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var gridCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(event.theme.gradient)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: event.wrappedIconName)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(primaryTextColor.opacity(0.18))
                        .rotationEffect(.degrees(-8))
                        .offset(x: 12, y: -6)
                }
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 82, height: 82)
                        .offset(x: 24, y: 24)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("\(max(0, event.daysRemaining(relativeTo: now)))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTextColor)

                Text(L10n.daysLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(primaryTextColor.opacity(0.9))

                Spacer(minLength: 12)

                Text(event.wrappedTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryTextColor)
                    .lineLimit(2)

                Text(dateLine)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 166, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: event.theme.tintColor.opacity(0.16), radius: 12, y: 7)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func titleBlock(color: Color, secondaryColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(event.wrappedTitle)
                    .lineLimit(1)
            } icon: {
                Image(systemName: event.wrappedIconName)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(color)

            Text(dateLine)
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryColor)
                .lineLimit(1)
        }
    }

    private var primaryTextColor: Color {
        Color.black.opacity(0.86)
    }

    private var secondaryTextColor: Color {
        Color.black.opacity(0.58)
    }

    private var dateLine: String {
        let targetDate = event.nextOccurrenceDate(relativeTo: now)

        if event.isAllDay {
            return targetDate.formatted(.dateTime.month(.abbreviated).day().year())
        }

        return targetDate.formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
    }
}
