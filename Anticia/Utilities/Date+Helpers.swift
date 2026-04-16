import Foundation

extension Date {
    nonisolated var shortMonthDay: String {
        formatted(.dateTime.month(.abbreviated).day())
    }

    nonisolated var monthAndYear: String {
        formatted(.dateTime.month(.wide).year())
    }

    nonisolated var timeLabel: String {
        formatted(.dateTime.hour().minute())
    }
}

extension Calendar {
    nonisolated func startOfMonth(for inputDate: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: inputDate)) ?? inputDate
    }

    nonisolated func daysInMonth(for inputDate: Date) -> [Date] {
        guard
            let interval = dateInterval(of: .month, for: inputDate),
            let firstWeek = dateInterval(of: .weekOfMonth, for: interval.start),
            let lastWeek = dateInterval(of: .weekOfMonth, for: interval.end - 1)
        else {
            return []
        }

        var days: [Date] = []
        var current = firstWeek.start

        while current < lastWeek.end {
            days.append(current)
            current = self.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return days
    }

    nonisolated func isSameMonth(_ lhs: Date, as rhs: Date) -> Bool {
        isDate(lhs, equalTo: rhs, toGranularity: .month)
    }
}
