import SwiftUI
import SwiftData

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let event: CountdownEntity?
    @State private var viewModel: EventEditorViewModel

    init(event: CountdownEntity?) {
        self.event = event
        _viewModel = State(initialValue: EventEditorViewModel(event: event))
    }

    var body: some View {
        Form {
            Section(String(localized: L10n.countdown)) {
                TextField(String(localized: L10n.title), text: $viewModel.title)
                Picker(String(localized: L10n.category), selection: $viewModel.category) {
                    ForEach(CountdownCategory.allCases) { category in
                        Label(category.title, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                .onChange(of: viewModel.category) { _, newValue in
                    viewModel.updateIconForCategory(newValue)
                }

                DatePicker(String(localized: L10n.date), selection: $viewModel.targetDate)
                Toggle(String(localized: L10n.allDay), isOn: $viewModel.isAllDay)
                Picker(String(localized: L10n.repeatRule), selection: $viewModel.repeatRule) {
                    ForEach(CountdownRepeatRule.allCases) { repeatRule in
                        Text(repeatRule.title)
                            .tag(repeatRule)
                    }
                }
                TextField(String(localized: L10n.location), text: $viewModel.location)
            }

            Section(String(localized: L10n.style)) {
                Picker(String(localized: L10n.cardStyle), selection: $viewModel.widgetStyle) {
                    ForEach(CountdownWidgetStyle.allCases) { style in
                        VStack(alignment: .leading) {
                            Text(style.title)
                            Text(style.subtitle)
                        }
                        .tag(style)
                    }
                }

                NavigationLink {
                    SymbolPickerView(selection: $viewModel.iconName)
                } label: {
                    HStack {
                        Label(String(localized: L10n.symbol), systemImage: viewModel.iconName)
                        Spacer()
                        Text(CountdownSymbolOption.title(for: viewModel.iconName))
                            .foregroundStyle(.secondary)
                    }
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(CountdownTheme.allCases) { item in
                            Button {
                                viewModel.theme = item
                            } label: {
                                Circle()
                                    .fill(item.gradient)
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if item == viewModel.theme {
                                            Circle()
                                                .stroke(Color.primary, lineWidth: 2)
                                                .padding(2)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }

            Section(String(localized: L10n.notes)) {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 140)
            }
        }
        .navigationTitle(String(localized: event == nil ? L10n.addCountdown : L10n.editCountdown))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.validateIcon()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(String(localized: L10n.cancel)) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: L10n.save)) {
                    save()
                }
                .disabled(viewModel.isSaveDisabled)
            }
        }
    }

    private func save() {
        let savedEvent = PersistenceController.save(
            event: event,
            draft: viewModel.draft,
            in: modelContext
        )
        dismiss()

        Task {
            await CountdownNotificationScheduler.scheduleStartNotification(for: savedEvent)
        }
    }
}
