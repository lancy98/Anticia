import SwiftUI

struct SettingsView: View {
    let onAddTapped: () -> Void

    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @AppStorage("userDisplayName") private var userDisplayName = ""

    var body: some View {
        List {
            Section {
                TextField(String(localized: L10n.name), text: $userDisplayName)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            } header: {
                Text(L10n.profile)
            } footer: {
                Text(L10n.settingsProfileFooter)
            }

            Section(String(localized: L10n.appearance)) {
                Picker(String(localized: L10n.theme), selection: $appAppearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance.rawValue)
                    }
                }
            }

            Section(String(localized: L10n.about)) {
                LabeledContent(String(localized: L10n.appVersion), value: "1.0")
            }
        }
        .navigationTitle(String(localized: L10n.settings))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: L10n.addCountdown), systemImage: "plus", action: onAddTapped)
            }
        }
    }
}
