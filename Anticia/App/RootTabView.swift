import Combine
import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [SortDescriptor(\CountdownEntity.targetDate, order: .forward)])
    private var events: [CountdownEntity]
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @State private var viewModel = RootTabViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        return tabContent(selectedTab: $viewModel.selectedTab)
            .sheet(isPresented: $viewModel.isPresentingEditor, onDismiss: viewModel.dismissEditor, content: {
                NavigationStack {
                    EventEditorView(event: viewModel.editorEvent)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            })
            .sheet(item: $viewModel.deepLinkedEvent) { event in
                NavigationStack {
                    EventDetailView(event: event)
                }
            }
            .preferredColorScheme(viewModel.selectedColorScheme(for: appAppearance))
            .tint(Color(hex: "2E6CF6"))
            .onAppear {
                refreshCountdownState()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshCountdownState()
                }
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                refreshCountdownState()
            }
            .onOpenURL { url in
                viewModel.handleDeepLink(url, events: events)
            }
    }

    @ViewBuilder
    private func tabContent(selectedTab: Binding<RootTab>) -> some View {
        if #available(iOS 18.0, *) {
            modernTabContent(selectedTab: selectedTab)
        } else {
            legacyTabContent(selectedTab: selectedTab)
        }
    }

    @available(iOS 18.0, *)
    private func modernTabContent(selectedTab: Binding<RootTab>) -> some View {
        TabView(selection: selectedTab) {
            Tab(String(localized: L10n.upcoming), systemImage: RootTab.upcoming.icon, value: .upcoming) {
                NavigationStack {
                    UpcomingView(now: viewModel.currentDate, onAddTapped: viewModel.presentCreateFlow)
                }
            }

            Tab(String(localized: L10n.calendar), systemImage: RootTab.calendar.icon, value: .calendar) {
                NavigationStack {
                    CalendarView(now: viewModel.currentDate, onAddTapped: viewModel.presentCreateFlow)
                }
            }

            Tab(String(localized: L10n.timeline), systemImage: RootTab.timeline.icon, value: .timeline) {
                NavigationStack {
                    TimelineView(now: viewModel.currentDate, onAddTapped: viewModel.presentCreateFlow)
                }
            }

            Tab(String(localized: L10n.completed), systemImage: RootTab.completed.icon, value: .completed) {
                NavigationStack {
                    CompletedView(now: viewModel.currentDate, onAddTapped: viewModel.presentCreateFlow)
                }
            }

            Tab(String(localized: L10n.settings), systemImage: RootTab.settings.icon, value: .settings) {
                NavigationStack {
                    SettingsView(onAddTapped: viewModel.presentCreateFlow)
                }
            }
        }
    }

    private func legacyTabContent(selectedTab: Binding<RootTab>) -> some View {
        TabView(selection: selectedTab) {
            NavigationStack {
                UpcomingView(now: viewModel.currentDate, onAddTapped: viewModel.presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.upcoming), systemImage: RootTab.upcoming.icon)
            }
            .tag(RootTab.upcoming)

            NavigationStack {
                CalendarView(now: viewModel.currentDate, onAddTapped: viewModel.presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.calendar), systemImage: RootTab.calendar.icon)
            }
            .tag(RootTab.calendar)

            NavigationStack {
                TimelineView(now: viewModel.currentDate, onAddTapped: viewModel.presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.timeline), systemImage: RootTab.timeline.icon)
            }
            .tag(RootTab.timeline)

            NavigationStack {
                CompletedView(now: viewModel.currentDate, onAddTapped: viewModel.presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.completed), systemImage: RootTab.completed.icon)
            }
            .tag(RootTab.completed)

            NavigationStack {
                SettingsView(onAddTapped: viewModel.presentCreateFlow)
            }
            .tabItem {
                Label(String(localized: L10n.settings), systemImage: RootTab.settings.icon)
            }
            .tag(RootTab.settings)
        }
    }

    private func refreshCountdownState() {
        viewModel.refreshDate()
        PersistenceController.completeExpiredEvents(in: modelContext)
        CountdownWidgetSnapshotStore.exportSnapshots(from: modelContext, now: viewModel.currentDate)
    }
}
