import SwiftUI
import SwiftData
import UserNotifications

@main
struct AnticiaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let notificationDelegate = CountdownNotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(PersistenceController.sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                try? PersistenceController.sharedModelContainer.mainContext.save()
            }
        }
    }
}
