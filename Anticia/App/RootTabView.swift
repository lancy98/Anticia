import Combine
import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @State private var selectedTab: RootTab = .upcoming
    @State private var editorEvent: CountdownEntity?
    @State private var isPresentingEditor = false
    @State private var currentDate = Date()

    var body: some View {
        tabContent
            .sheet(isPresented: $isPresentingEditor, onDismiss: { editorEvent = nil }, content: {
                NavigationStack {
                    EventEditorView(event: editorEvent)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            })
            .preferredColorScheme(selectedColorScheme)
            .tint(Color(hex: "2E6CF6"))
            .onAppear {
                currentDate = .now
                completeExpiredEvents()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    currentDate = .now
                    completeExpiredEvents()
                }
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                currentDate = .now
                completeExpiredEvents()
            }
    }

    @ViewBuilder
    private var tabContent: some View {
        if #available(iOS 18.0, *) {
            modernTabContent
        } else {
            legacyTabContent
        }
    }

    @available(iOS 18.0, *)
    private var modernTabContent: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: L10n.upcoming), systemImage: RootTab.upcoming.icon, value: .upcoming) {
                NavigationStack {
                    UpcomingView(now: currentDate, onAddTapped: presentCreateFlow)
                }
            }

            Tab(String(localized: L10n.calendar), systemImage: RootTab.calendar.icon, value: .calendar) {
                NavigationStack {
                    CalendarView(now: currentDate, onAddTapped: presentCreateFlow)
                }
            }

            Tab(String(localized: L10n.timeline), systemImage: RootTab.timeline.icon, value: .timeline) {
                NavigationStack {
                    TimelineView(now: currentDate, onAddTapped: presentCreateFlow)
                }
            }

            Tab(String(localized: L10n.completed), systemImage: RootTab.completed.icon, value: .completed) {
                NavigationStack {
                    CompletedView(now: currentDate, onAddTapped: presentCreateFlow)
                }
            }

            Tab(String(localized: L10n.settings), systemImage: RootTab.settings.icon, value: .settings) {
                NavigationStack {
                    SettingsView(onAddTapped: presentCreateFlow)
                }
            }
        }
    }

    private var legacyTabContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                UpcomingView(now: currentDate, onAddTapped: presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.upcoming), systemImage: RootTab.upcoming.icon)
            }
            .tag(RootTab.upcoming)

            NavigationStack {
                CalendarView(now: currentDate, onAddTapped: presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.calendar), systemImage: RootTab.calendar.icon)
            }
            .tag(RootTab.calendar)

            NavigationStack {
                TimelineView(now: currentDate, onAddTapped: presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.timeline), systemImage: RootTab.timeline.icon)
            }
            .tag(RootTab.timeline)

            NavigationStack {
                CompletedView(now: currentDate, onAddTapped: presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.completed), systemImage: RootTab.completed.icon)
            }
            .tag(RootTab.completed)

            NavigationStack {
                SettingsView(onAddTapped: presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.settings), systemImage: RootTab.settings.icon)
            }
            .tag(RootTab.settings)
        }
    }

    private var selectedColorScheme: ColorScheme? {
        AppAppearance(rawValue: appAppearance)?.colorScheme
    }

    private func presentCreateFlow() {
        editorEvent = nil
        isPresentingEditor = true
    }

    private func completeExpiredEvents() {
        PersistenceController.completeExpiredEvents(in: modelContext)
    }
}

private enum RootTab: Hashable {
    case upcoming
    case calendar
    case timeline
    case completed
    case settings

    var icon: String {
        switch self {
        case .upcoming:
            return "sparkles"
        case .calendar:
            return "calendar"
        case .timeline:
            return "list.bullet.rectangle.portrait"
        case .completed:
            return "checkmark.seal"
        case .settings:
            return "gearshape"
        }
    }
}
