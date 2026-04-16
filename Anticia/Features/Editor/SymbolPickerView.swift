import SwiftUI

struct SymbolPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: String
    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 76), spacing: 12)
    ]

    private var filteredSections: [CountdownSymbolSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return CountdownSymbolSection.all }

        return CountdownSymbolSection.all.compactMap { section in
            let options = section.options.filter { option in
                option.matches(query)
            }

            guard !options.isEmpty else { return nil }
            return CountdownSymbolSection(title: section.title, options: options)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(filteredSections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.localizedTitle)
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(section.options) { option in
                                SymbolOptionButton(
                                    option: option,
                                    isSelected: selection == option.name
                                ) {
                                    selection = option.name
                                    dismiss()
                                }
                            }
                        }
                    }
                }

                if filteredSections.isEmpty {
                    ContentUnavailableView(
                        String(localized: L10n.noSymbolsFound),
                        systemImage: "magnifyingglass",
                        description: Text(L10n.tryDifferentSearch)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 96)
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: L10n.chooseSymbol))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: String(localized: L10n.searchSymbols))
    }
}

private struct SymbolOptionButton: View {
    let option: CountdownSymbolOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: option.name)
                    .font(.title2)
                    .frame(height: 28)

                Text(option.title)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityValue(option.name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct CountdownSymbolOption: Identifiable, Hashable {
    let name: String
    let keywords: [String]

    var id: String { name }
    var title: String {
        let key = "symbol.title.\(name)"
        let localizedTitle = Bundle.main.localizedString(forKey: key, value: nil, table: nil)

        if localizedTitle != key {
            return localizedTitle
        }

        return Self.readableTitle(for: name)
    }

    init(name: String, keywords: [String] = []) {
        self.name = name
        self.keywords = keywords
    }

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.localizedStandardContains(".") ? query : query.replacing(" ", with: "")

        if title.localizedStandardContains(query) || name.localizedStandardContains(query) {
            return true
        }

        if name.replacing(".", with: "").localizedStandardContains(normalizedQuery) {
            return true
        }

        return keywords.contains { $0.localizedStandardContains(query) }
    }

    static let all: [CountdownSymbolOption] = CountdownSymbolSection.all.flatMap(\.options)
    static let allNames = Set(all.map(\.name))

    static func title(for name: String) -> String {
        all.first { $0.name == name }?.title ?? readableTitle(for: name)
    }

    private static func readableTitle(for name: String) -> String {
        name
            .split(separator: ".")
            .filter { $0 != "fill" }
            .map { word in
                word
                    .replacing("mappin", with: "map pin")
                    .replacing("laptopcomputer", with: "laptop")
                    .replacing("desktopcomputer", with: "desktop")
                    .replacing("pianokeys", with: "piano keys")
                    .replacing("gamecontroller", with: "game controller")
                    .replacing("creditcard", with: "credit card")
                    .replacing("pawprint", with: "paw print")
                    .capitalized
            }
            .joined(separator: " ")
    }
}

struct CountdownSymbolSection: Identifiable {
    let title: LocalizedStringResource
    let options: [CountdownSymbolOption]

    var id: String { String(localized: title) }
    var localizedTitle: String { String(localized: title) }

    static let all: [CountdownSymbolSection] = [
        CountdownSymbolSection(
            title: L10n.symbolSectionSuggested,
            options: [
                CountdownSymbolOption(name: "airplane", keywords: ["travel", "flight"]),
                CountdownSymbolOption(name: "gift.fill", keywords: ["birthday", "present"]),
                CountdownSymbolOption(name: "heart.fill", keywords: ["anniversary", "love"]),
                CountdownSymbolOption(name: "sparkles", keywords: ["holiday", "celebration"]),
                CountdownSymbolOption(name: "briefcase.fill", keywords: ["job", "office"]),
                CountdownSymbolOption(name: "person.fill", keywords: ["personal", "profile"]),
                CountdownSymbolOption(name: "calendar", keywords: ["date", "event"]),
                CountdownSymbolOption(name: "flag.fill", keywords: ["milestone", "finish"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionTravel,
            options: [
                CountdownSymbolOption(name: "airplane", keywords: ["trip", "flight"]),
                CountdownSymbolOption(name: "airplane.departure", keywords: ["flight", "leave"]),
                CountdownSymbolOption(name: "airplane.arrival", keywords: ["flight", "land"]),
                CountdownSymbolOption(name: "suitcase.fill", keywords: ["bag", "luggage"]),
                CountdownSymbolOption(name: "bag.fill", keywords: ["luggage", "packing"]),
                CountdownSymbolOption(name: "map.fill", keywords: ["travel", "place"]),
                CountdownSymbolOption(name: "mappin.and.ellipse", keywords: ["location", "place"]),
                CountdownSymbolOption(name: "location.fill", keywords: ["place", "gps"]),
                CountdownSymbolOption(name: "globe", keywords: ["world", "international"]),
                CountdownSymbolOption(name: "car.fill", keywords: ["drive", "road"]),
                CountdownSymbolOption(name: "bus.fill", keywords: ["transit", "travel"]),
                CountdownSymbolOption(name: "tram.fill", keywords: ["rail", "transit"]),
                CountdownSymbolOption(name: "ferry.fill", keywords: ["boat", "ship"]),
                CountdownSymbolOption(name: "bicycle", keywords: ["cycle", "ride"]),
                CountdownSymbolOption(name: "figure.walk", keywords: ["hike", "travel"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionCelebration,
            options: [
                CountdownSymbolOption(name: "gift.fill", keywords: ["present", "birthday"]),
                CountdownSymbolOption(name: "birthday.cake.fill", keywords: ["birthday", "party"]),
                CountdownSymbolOption(name: "party.popper.fill", keywords: ["celebrate", "confetti"]),
                CountdownSymbolOption(name: "balloon.fill", keywords: ["party", "celebration"]),
                CountdownSymbolOption(name: "sparkles", keywords: ["magic", "celebrate"]),
                CountdownSymbolOption(name: "star.fill", keywords: ["favorite", "special"]),
                CountdownSymbolOption(name: "crown.fill", keywords: ["special", "queen", "king"]),
                CountdownSymbolOption(name: "trophy.fill", keywords: ["award", "win"]),
                CountdownSymbolOption(name: "medal.fill", keywords: ["award", "achievement"]),
                CountdownSymbolOption(name: "rosette", keywords: ["award", "badge"]),
                CountdownSymbolOption(name: "fireworks", keywords: ["celebrate", "holiday"]),
                CountdownSymbolOption(name: "theatermasks.fill", keywords: ["event", "theater"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionLovePeople,
            options: [
                CountdownSymbolOption(name: "heart.fill", keywords: ["love", "anniversary"]),
                CountdownSymbolOption(
                    name: "heart.circle.fill",
                    keywords: ["anniversary", "relationship"]
                ),
                CountdownSymbolOption(name: "heart.text.square.fill", keywords: ["love", "message"]),
                CountdownSymbolOption(name: "person.fill", keywords: ["personal", "profile"]),
                CountdownSymbolOption(name: "person.2.fill", keywords: ["friends", "couple"]),
                CountdownSymbolOption(name: "person.3.fill", keywords: ["family", "team"]),
                CountdownSymbolOption(
                    name: "figure.2.and.child.holdinghands",
                    keywords: ["child", "people"]
                ),
                CountdownSymbolOption(name: "hands.sparkles.fill", keywords: ["help", "clean"]),
                CountdownSymbolOption(name: "hand.raised.fill", keywords: ["promise", "stop"]),
                CountdownSymbolOption(name: "hand.thumbsup.fill", keywords: ["yes", "approve"]),
                CountdownSymbolOption(name: "face.smiling.fill", keywords: ["happy", "joy"]),
                CountdownSymbolOption(name: "message.fill", keywords: ["chat", "text"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionWorkSchool,
            options: [
                CountdownSymbolOption(name: "briefcase.fill", keywords: ["job", "office"]),
                CountdownSymbolOption(name: "laptopcomputer", keywords: ["computer", "work"]),
                CountdownSymbolOption(name: "desktopcomputer", keywords: ["computer", "office"]),
                CountdownSymbolOption(name: "keyboard.fill", keywords: ["typing", "work"]),
                CountdownSymbolOption(name: "paperclip", keywords: ["attachment", "office"]),
                CountdownSymbolOption(name: "doc.text.fill", keywords: ["paper", "file"]),
                CountdownSymbolOption(name: "folder.fill", keywords: ["files", "project"]),
                CountdownSymbolOption(name: "tray.full.fill", keywords: ["mail", "tasks"]),
                CountdownSymbolOption(name: "chart.bar.fill", keywords: ["analytics", "report"]),
                CountdownSymbolOption(name: "building.2.fill", keywords: ["company", "work"]),
                CountdownSymbolOption(name: "graduationcap.fill", keywords: ["study", "college"]),
                CountdownSymbolOption(name: "book.fill", keywords: ["read", "study"]),
                CountdownSymbolOption(name: "books.vertical.fill", keywords: ["library", "study"]),
                CountdownSymbolOption(name: "pencil", keywords: ["write", "study"]),
                CountdownSymbolOption(name: "studentdesk", keywords: ["school", "study"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionDatesTime,
            options: [
                CountdownSymbolOption(name: "calendar", keywords: ["date", "event"]),
                CountdownSymbolOption(name: "calendar.circle.fill", keywords: ["calendar", "event"]),
                CountdownSymbolOption(name: "calendar.badge.plus", keywords: ["new", "event"]),
                CountdownSymbolOption(name: "calendar.badge.clock", keywords: ["time", "plan"]),
                CountdownSymbolOption(name: "clock.fill", keywords: ["time", "deadline"]),
                CountdownSymbolOption(name: "alarm.fill", keywords: ["wake", "reminder"]),
                CountdownSymbolOption(name: "timer", keywords: ["countdown", "time"]),
                CountdownSymbolOption(name: "hourglass", keywords: ["wait", "time"]),
                CountdownSymbolOption(name: "stopwatch.fill", keywords: ["time", "race"]),
                CountdownSymbolOption(name: "bell.fill", keywords: ["alert", "notify"]),
                CountdownSymbolOption(name: "bell.badge.fill", keywords: ["notify", "reminder"]),
                CountdownSymbolOption(name: "checkmark.circle.fill", keywords: ["complete", "finished"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionGoals,
            options: [
                CountdownSymbolOption(name: "flag.fill", keywords: ["goal", "finish"]),
                CountdownSymbolOption(name: "target", keywords: ["goal", "focus"]),
                CountdownSymbolOption(name: "scope", keywords: ["focus", "aim"]),
                CountdownSymbolOption(name: "mountain.2.fill", keywords: ["goal", "climb"]),
                CountdownSymbolOption(name: "figure.run", keywords: ["fitness", "race"]),
                CountdownSymbolOption(
                    name: "figure.strengthtraining.traditional",
                    keywords: ["fitness", "gym"]
                ),
                CountdownSymbolOption(name: "dumbbell.fill", keywords: ["fitness", "workout"]),
                CountdownSymbolOption(name: "bolt.fill", keywords: ["power", "fast"]),
                CountdownSymbolOption(name: "flame.fill", keywords: ["fire", "habit"]),
                CountdownSymbolOption(name: "star.circle.fill", keywords: ["goal", "special"]),
                CountdownSymbolOption(name: "checklist", keywords: ["tasks", "todo"]),
                CountdownSymbolOption(name: "list.bullet.clipboard.fill", keywords: ["todo", "plan"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionHomeLife,
            options: [
                CountdownSymbolOption(name: "house.fill", keywords: ["moving", "family"]),
                CountdownSymbolOption(name: "building.columns.fill", keywords: ["money", "finance"]),
                CountdownSymbolOption(name: "cart.fill", keywords: ["store", "buy"]),
                CountdownSymbolOption(name: "creditcard.fill", keywords: ["pay", "money"]),
                CountdownSymbolOption(name: "banknote.fill", keywords: ["money", "finance"]),
                CountdownSymbolOption(name: "fork.knife", keywords: ["food", "restaurant"]),
                CountdownSymbolOption(name: "cup.and.saucer.fill", keywords: ["drink", "cafe"]),
                CountdownSymbolOption(name: "wineglass.fill", keywords: ["dinner", "celebrate"]),
                CountdownSymbolOption(name: "carrot.fill", keywords: ["meal", "healthy"]),
                CountdownSymbolOption(name: "leaf.fill", keywords: ["nature", "break"]),
                CountdownSymbolOption(name: "tree.fill", keywords: ["nature", "outdoor"]),
                CountdownSymbolOption(name: "pawprint.fill", keywords: ["animal", "dog", "cat"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionHealth,
            options: [
                CountdownSymbolOption(name: "cross.case.fill", keywords: ["medical", "first aid"]),
                CountdownSymbolOption(name: "heart.text.square.fill", keywords: ["health", "medical"]),
                CountdownSymbolOption(name: "pills.fill", keywords: ["health", "doctor"]),
                CountdownSymbolOption(name: "stethoscope", keywords: ["medical", "health"]),
                CountdownSymbolOption(name: "bed.double.fill", keywords: ["sleep", "health"]),
                CountdownSymbolOption(name: "lungs.fill", keywords: ["health", "wellness"]),
                CountdownSymbolOption(name: "brain.head.profile", keywords: ["mental", "focus"]),
                CountdownSymbolOption(name: "figure.mind.and.body", keywords: ["meditate", "yoga"]),
                CountdownSymbolOption(name: "drop.fill", keywords: ["drink", "hydration"]),
                CountdownSymbolOption(name: "sun.max.fill", keywords: ["morning", "outside"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionHobbies,
            options: [
                CountdownSymbolOption(name: "music.note", keywords: ["song", "concert"]),
                CountdownSymbolOption(name: "guitars.fill", keywords: ["music", "instrument"]),
                CountdownSymbolOption(name: "pianokeys", keywords: ["music", "instrument"]),
                CountdownSymbolOption(name: "camera.fill", keywords: ["photo", "picture"]),
                CountdownSymbolOption(name: "photo.fill", keywords: ["image", "memory"]),
                CountdownSymbolOption(name: "paintpalette.fill", keywords: ["paint", "creative"]),
                CountdownSymbolOption(name: "gamecontroller.fill", keywords: ["play", "gaming"]),
                CountdownSymbolOption(name: "film.fill", keywords: ["cinema", "video"]),
                CountdownSymbolOption(name: "tv.fill", keywords: ["show", "watch"]),
                CountdownSymbolOption(name: "headphones", keywords: ["music", "listen"]),
                CountdownSymbolOption(name: "mic.fill", keywords: ["record", "sing"]),
                CountdownSymbolOption(name: "paintbrush.fill", keywords: ["art", "paint"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionWeatherSeasons,
            options: [
                CountdownSymbolOption(name: "sun.max.fill", keywords: ["summer", "day"]),
                CountdownSymbolOption(name: "moon.stars.fill", keywords: ["moon", "evening"]),
                CountdownSymbolOption(name: "cloud.sun.fill", keywords: ["sun", "weather"]),
                CountdownSymbolOption(name: "cloud.fill", keywords: ["weather", "sky"]),
                CountdownSymbolOption(name: "cloud.rain.fill", keywords: ["weather", "storm"]),
                CountdownSymbolOption(name: "cloud.snow.fill", keywords: ["winter", "weather"]),
                CountdownSymbolOption(name: "snowflake", keywords: ["snow", "cold"]),
                CountdownSymbolOption(name: "umbrella.fill", keywords: ["rain", "weather"]),
                CountdownSymbolOption(name: "wind", keywords: ["weather", "air"]),
                CountdownSymbolOption(name: "thermometer.sun.fill", keywords: ["temperature", "summer"])
            ]
        ),
        CountdownSymbolSection(
            title: L10n.symbolSectionSimple,
            options: [
                CountdownSymbolOption(name: "circle.fill", keywords: ["shape"]),
                CountdownSymbolOption(name: "square.fill", keywords: ["shape"]),
                CountdownSymbolOption(name: "triangle.fill", keywords: ["shape"]),
                CountdownSymbolOption(name: "diamond.fill", keywords: ["shape"]),
                CountdownSymbolOption(name: "hexagon.fill", keywords: ["shape"]),
                CountdownSymbolOption(name: "seal.fill", keywords: ["badge"]),
                CountdownSymbolOption(name: "bookmark.fill", keywords: ["save"]),
                CountdownSymbolOption(name: "pin.fill", keywords: ["save", "mark"]),
                CountdownSymbolOption(name: "tag.fill", keywords: ["label"]),
                CountdownSymbolOption(name: "paperplane.fill", keywords: ["message"]),
                CountdownSymbolOption(name: "link", keywords: ["url"]),
                CountdownSymbolOption(name: "plus.circle.fill", keywords: ["add"])
            ]
        )
    ]
}
