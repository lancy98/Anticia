import SwiftUI
import SwiftData
import PhotosUI

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let event: CountdownEntity?
    @State private var viewModel: EventEditorViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isCropPresented = false

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

            }

            Section(String(localized: "appearance.preview")) {
                SimpleCountdownCard(
                    event: viewModel.previewEvent,
                    style: viewModel.widgetStyle,
                    now: .now,
                    appearanceOverride: viewModel.appearance,
                    previewImage: viewModel.appearance.backgroundKind == .photo ? viewModel.pendingPhotoImage : nil
                )
                .frame(width: viewModel.widgetStyle == .grid ? 180 : nil,
                       height: viewModel.widgetStyle == .grid ? 210 : nil)
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            backgroundSection
            textColorSection

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
        .onDisappear {
            viewModel.cancelPhotoImport()
        }
        .onChange(of: selectedPhotoItem) { _, item in
            if let item { viewModel.importPhoto(item) }
        }
        .onChange(of: viewModel.isPhotoLoading) { _, isLoading in
            if !isLoading { selectedPhotoItem = nil }
        }
        .sheet(isPresented: $isCropPresented) {
            if let image = viewModel.backgroundImage {
                CountdownImageCropView(
                    appearance: $viewModel.appearance,
                    event: viewModel.previewEvent,
                    style: viewModel.widgetStyle,
                    image: image
                )
            }
        }
        .alert(
            String(localized: "appearance.errorTitle"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "appearance.ok"), role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(String(localized: L10n.cancel)) {
                    viewModel.cancelPhotoImport()
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

    private var backgroundSection: some View {
        Section {
            Picker(
                String(localized: "appearance.background"),
                selection: Binding(
                    get: { viewModel.selectedBackgroundKind },
                    set: { viewModel.selectBackgroundKind($0) }
                )
            ) {
                Text("appearance.gradient").tag(CountdownBackgroundKind.gradient)
                Text("appearance.samples").tag(CountdownBackgroundKind.sample)
                Text("appearance.myPhoto").tag(CountdownBackgroundKind.photo)
            }
            .pickerStyle(.segmented)

            switch viewModel.selectedBackgroundKind {
            case .gradient:
                gradientChoices
            case .sample:
                sampleChoices
            case .photo:
                photoControls
            }

            if viewModel.appearance.backgroundKind != .gradient {
                if viewModel.backgroundImage != nil {
                    Button {
                        isCropPresented = true
                    } label: {
                        Label(String(localized: "appearance.reposition"), systemImage: "crop")
                    }
                    .disabled(viewModel.isPhotoLoading)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("appearance.dimming")
                        Spacer()
                        Text(viewModel.appearance.dimAmount, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.appearance.dimAmount, in: 0...0.8)
                        .accessibilityLabel(Text("appearance.dimming"))
                }
            }
        } header: {
            Text("appearance.background")
        } footer: {
            Text("appearance.backgroundHint")
        }
    }

    private var gradientChoices: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(CountdownTheme.allCases) { item in
                    Button {
                        viewModel.theme = item
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(item.gradient)
                                .frame(width: 42, height: 42)
                                .overlay {
                                    if item == viewModel.theme {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.bold))
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.5), radius: 2)
                                    }
                                }
                            Text(item.title)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .frame(minWidth: 50, minHeight: 64)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.title)
                    .accessibilityAddTraits(item == viewModel.theme ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private var sampleChoices: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(CountdownBackgroundSample.allCases) { sample in
                    Button {
                        viewModel.selectSample(sample)
                    } label: {
                        VStack(spacing: 7) {
                            Image(sample.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 108, height: 76)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(alignment: .topTrailing) {
                                    if sample == viewModel.selectedSample {
                                        Image(systemName: "checkmark.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, Color.accentColor)
                                            .padding(6)
                                    }
                                }
                            Text(sample.title)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(sample.title)
                    .accessibilityAddTraits(sample == viewModel.selectedSample ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private var photoControls: some View {
        let pickerTitle = viewModel.hasPhoto
            ? String(localized: "appearance.replacePhoto")
            : String(localized: "appearance.choosePhoto")

        return Group {
            if viewModel.isPhotoLoading {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("appearance.loadingPhoto")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(String(localized: L10n.cancel)) {
                        viewModel.cancelPhotoImport()
                        selectedPhotoItem = nil
                    }
                }
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(
                        pickerTitle,
                        systemImage: "photo.on.rectangle"
                    )
                }

                if viewModel.hasPhoto {
                    Button(role: .destructive) {
                        selectedPhotoItem = nil
                        viewModel.removePhoto()
                    } label: {
                        Label(String(localized: "appearance.removePhoto"), systemImage: "trash")
                    }
                } else {
                    Text("appearance.photoHint")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var textColorSection: some View {
        Section {
            Button {
                viewModel.appearance.textColorHex = nil
            } label: {
                HStack {
                    Text("appearance.automaticColor")
                    Spacer()
                    if viewModel.appearance.textColorHex == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .accessibilityAddTraits(viewModel.appearance.textColorHex == nil ? .isSelected : [])

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(CountdownTextColorOption.allCases) { option in
                        Button {
                            viewModel.appearance.textColorHex = option.hex
                        } label: {
                            Circle()
                                .fill(Color(hex: option.hex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1)
                                }
                                .overlay {
                                    if viewModel.appearance.textColorHex?.uppercased() == option.hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(option.checkmarkColor)
                                    }
                                }
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.title)
                        .accessibilityAddTraits(
                            viewModel.appearance.textColorHex?.uppercased() == option.hex ? .isSelected : []
                        )
                    }
                }
            }
            .scrollIndicators(.hidden)

            ColorPicker(
                String(localized: "appearance.customColor"),
                selection: $viewModel.textColor,
                supportsOpacity: false
            )
        } header: {
            Text("appearance.textColor")
        } footer: {
            Text("appearance.textColorHint")
        }
    }

    private func save() {
        guard !viewModel.isSaveDisabled else { return }
        do {
            let savedEvent = try viewModel.save(event: event, in: modelContext)
            dismiss()

            Task {
                await CountdownNotificationScheduler.scheduleStartNotification(for: savedEvent)
            }
        } catch {
            viewModel.errorMessage = String(localized: "appearance.saveError")
        }
    }
}
