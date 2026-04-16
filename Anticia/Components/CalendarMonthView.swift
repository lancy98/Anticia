import SwiftUI

struct CalendarMonthView: View {
    @Binding var selectedDate: Date
    let month: Date
    let events: [CountdownEntity]
    let now: Date

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(month.monthAndYear)
                    .font(.title3.weight(.bold))
                Spacer()
                Text(L10n.calendarModeMonth)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 12) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.prefix(1))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                ForEach(calendar.daysInMonth(for: month), id: \.self) { day in
                    let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                    let isInMonth = calendar.isSameMonth(day, as: month)
                    let dayEvents = events.filter {
                        calendar.isDate($0.nextOccurrenceDate(relativeTo: now), inSameDayAs: day)
                    }

                    Button {
                        selectedDate = day
                    } label: {
                        VStack(spacing: 6) {
                            Text(day.formatted(.dateTime.day()))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : isInMonth ? .primary : .secondary.opacity(0.4))

                            if dayEvents.isEmpty {
                                Circle()
                                    .fill(.clear)
                                    .frame(width: 6, height: 6)
                            } else {
                                HStack(spacing: 3) {
                                    ForEach(dayEvents.prefix(2), id: \.wrappedID) { event in
                                        Circle()
                                            .fill(event.theme.tintColor)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isSelected ? AnyShapeStyle(Color(hex: "2E6CF6")) : AnyShapeStyle(Color.clear))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isInMonth)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}
