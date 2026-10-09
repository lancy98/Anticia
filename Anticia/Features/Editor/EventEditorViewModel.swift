import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

@Observable
@MainActor
final class EventEditorViewModel {
    var title: String
    var category: CountdownCategory
    var targetDate: Date
    var location: String
    var notes: String
    var theme: CountdownTheme
    var iconName: String
    var isAllDay: Bool
    var repeatRule: CountdownRepeatRule
    var widgetStyle: CountdownWidgetStyle
    var appearance: CountdownAppearance
    var selectedBackgroundKind: CountdownBackgroundKind
    var selectedSample: CountdownBackgroundSample
    var isPhotoLoading = false
    var errorMessage: String?
    private(set) var pendingPhotoData: Data?
    private(set) var pendingPhotoImage: UIImage?

    @ObservationIgnored private var photoLoadTask: Task<Void, Never>?
    @ObservationIgnored private var photoLoadID: UUID?
    @ObservationIgnored private var storedPhotoName: String?

    init(event: CountdownEntity?) {
        title = event?.wrappedTitle ?? ""
        category = event?.category ?? .travel
        targetDate = event?.originalTargetDate ?? .now
        location = event?.location ?? ""
        notes = event?.notes ?? ""
        theme = event?.theme ?? .ocean
        iconName = event?.wrappedIconName ?? CountdownCategory.travel.systemImage
        isAllDay = event?.isAllDay ?? true
        repeatRule = event?.repeatRule ?? .never
        widgetStyle = event?.widgetStyle ?? .classic
        let initialAppearance = event?.appearance ?? CountdownAppearance()
        appearance = initialAppearance
        selectedBackgroundKind = initialAppearance.backgroundKind
        selectedSample = CountdownBackgroundSample.allCases.first {
            $0.imageName == initialAppearance.imageName
        } ?? .coast
        storedPhotoName = initialAppearance.backgroundKind == .photo ? initialAppearance.imageName : nil
    }

    var isSaveDisabled: Bool {
        isPhotoLoading || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var draft: CountdownDraft {
        draft(with: appearance)
    }

    private func draft(with appearance: CountdownAppearance) -> CountdownDraft {
        CountdownDraft(
            title: title,
            category: category,
            targetDate: targetDate,
            location: location,
            notes: notes,
            theme: theme,
            iconName: iconName,
            isAllDay: isAllDay,
            repeatRule: repeatRule,
            widgetStyle: widgetStyle,
            appearance: appearance
        )
    }

    /// A detached model gives the preview the same formatting as a saved countdown.
    /// It is never inserted into the editor's model context.
    var previewEvent: CountdownEntity {
        CountdownEntity(
            iconName: iconName,
            isAllDay: isAllDay,
            location: location,
            notes: notes,
            categoryRawValue: category.rawValue,
            repeatRuleRawValue: repeatRule.rawValue,
            targetDate: targetDate,
            themeRawValue: theme.rawValue,
            title: title,
            widgetStyleRawValue: widgetStyle.rawValue
        )
    }

    var backgroundImage: UIImage? {
        if appearance.backgroundKind == .photo, let pendingPhotoImage {
            return pendingPhotoImage
        }
        guard let name = appearance.imageName else { return nil }
        return CountdownImageStore.image(named: name, kind: appearance.backgroundKind)
    }

    var hasPhoto: Bool {
        pendingPhotoImage != nil || storedPhotoName != nil
    }

    var textColor: Color {
        get {
            if let hex = appearance.textColorHex {
                return Color(hex: hex)
            }
            return appearance.backgroundKind == .gradient ? Color(hex: "242424") : .white
        }
        set {
            appearance.textColorHex = newValue.hexRGB
        }
    }

    func selectBackgroundKind(_ kind: CountdownBackgroundKind) {
        selectedBackgroundKind = kind
        if kind != .photo { cancelPhotoImport() }

        switch kind {
        case .gradient:
            appearance.backgroundKind = .gradient
            appearance.imageName = nil
            resetImagePosition()
        case .sample:
            selectSample(selectedSample)
        case .photo:
            // Keep the current background until the user picks a photo.
            if hasPhoto {
                let wasPhoto = appearance.backgroundKind == .photo
                appearance.backgroundKind = .photo
                appearance.imageName = pendingPhotoData == nil ? storedPhotoName : nil
                if !wasPhoto { resetImagePosition() }
            }
        }
    }

    func selectSample(_ sample: CountdownBackgroundSample) {
        cancelPhotoImport()
        let wasImage = appearance.backgroundKind != .gradient
        selectedBackgroundKind = .sample
        selectedSample = sample
        appearance.backgroundKind = .sample
        appearance.imageName = sample.imageName
        if !wasImage { appearance.dimAmount = 0.25 }
        resetImagePosition()
    }

    func importPhoto(_ item: PhotosPickerItem) {
        cancelPhotoImport()
        let loadID = UUID()
        photoLoadID = loadID
        isPhotoLoading = true
        errorMessage = nil

        photoLoadTask = Task { [weak self] in
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw PhotoImportError.unreadable
                }
                try Task.checkCancellation()
                let preparedData = try await CountdownImageStore.preparePhoto(data: data)
                try Task.checkCancellation()
                guard let image = UIImage(data: preparedData) else {
                    throw PhotoImportError.unreadable
                }
                guard let self, self.photoLoadID == loadID else { return }

                let wasImage = self.appearance.backgroundKind != .gradient
                self.pendingPhotoData = preparedData
                self.pendingPhotoImage = image
                self.selectedBackgroundKind = .photo
                self.appearance.backgroundKind = .photo
                self.appearance.imageName = nil
                if !wasImage { self.appearance.dimAmount = 0.25 }
                self.resetImagePosition()
                self.finishPhotoImport(loadID: loadID)
            } catch {
                guard let self, self.photoLoadID == loadID else { return }
                if !Task.isCancelled {
                    self.errorMessage = String(localized: "appearance.photoError")
                }
                self.finishPhotoImport(loadID: loadID)
            }
        }
    }

    func cancelPhotoImport() {
        photoLoadTask?.cancel()
        photoLoadTask = nil
        photoLoadID = nil
        isPhotoLoading = false
    }

    func removePhoto() {
        cancelPhotoImport()
        pendingPhotoData = nil
        pendingPhotoImage = nil
        storedPhotoName = nil
        selectBackgroundKind(.gradient)
    }

    func save(event: CountdownEntity?, in context: ModelContext) throws -> CountdownEntity {
        var savedAppearance = appearance
        var newPhotoName: String?

        do {
            if savedAppearance.backgroundKind == .photo, let data = pendingPhotoData {
                let name = try CountdownImageStore.savePhoto(data: data)
                newPhotoName = name
                savedAppearance.imageName = name
            }

            let savedEvent = try PersistenceController.save(
                event: event,
                draft: draft(with: savedAppearance),
                in: context
            )
            appearance = savedAppearance
            storedPhotoName = savedAppearance.backgroundKind == .photo ? savedAppearance.imageName : nil
            pendingPhotoData = nil
            pendingPhotoImage = nil
            return savedEvent
        } catch {
            if let newPhotoName { CountdownImageStore.removePhoto(named: newPhotoName) }
            throw error
        }
    }

    private func resetImagePosition() {
        appearance.imageScale = 1
        appearance.imagePositionX = 0.5
        appearance.imagePositionY = 0.5
    }

    private func finishPhotoImport(loadID: UUID) {
        guard photoLoadID == loadID else { return }
        photoLoadID = nil
        photoLoadTask = nil
        isPhotoLoading = false
    }

    private enum PhotoImportError: Error {
        case unreadable
    }

    func updateIconForCategory(_ newValue: CountdownCategory) {
        if iconName.isEmpty || CountdownCategory.allCases.map(\.systemImage).contains(iconName) {
            iconName = newValue.systemImage
        }
    }

    func validateIcon() {
        if !CountdownSymbolOption.allNames.contains(iconName) {
            iconName = category.systemImage
        }
    }
}
