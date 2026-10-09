import ImageIO
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import XCTest
@testable import Anticia

final class CountdownAppearanceTests: XCTestCase {
    @MainActor
    func testCountdownWithoutAppearanceMetadataKeepsLegacyDefaultsAfterSave() throws {
        let container = try makeMemoryContainer()
        let event = makeCountdown()
        container.mainContext.insert(event)
        try container.mainContext.save()

        let loaded = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<CountdownEntity>()).first)
        XCTAssertNil(loaded.backgroundKindRawValue)
        XCTAssertNil(loaded.backgroundImageName)
        XCTAssertNil(loaded.textColorHex)
        XCTAssertNil(loaded.backgroundDimAmount)
        XCTAssertNil(loaded.backgroundImageScale)
        XCTAssertNil(loaded.backgroundImagePositionX)
        XCTAssertNil(loaded.backgroundImagePositionY)
        XCTAssertEqual(loaded.appearance, CountdownAppearance())
        XCTAssertEqual(loaded.appearance.foregroundColor(default: .black).hexRGB, "000000")
    }

    @MainActor
    func testSavedPhotoAppearanceRoundTripsThroughSwiftData() throws {
        let container = try makeMemoryContainer()
        let event = makeCountdown()
        let expected = CountdownAppearance(
            backgroundKind: .photo,
            imageName: "\(UUID().uuidString).jpg",
            textColorHex: "2A7CBF",
            dimAmount: 0.4,
            imageScale: 1.8,
            imagePositionX: 0.2,
            imagePositionY: 0.75
        )
        event.appearance = expected
        container.mainContext.insert(event)
        try container.mainContext.save()

        let loaded = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<CountdownEntity>()).first)
        XCTAssertEqual(loaded.appearance, expected)
        XCTAssertEqual(loaded.appearance.foregroundColor().hexRGB, "2A7CBF")
        XCTAssertEqual(loaded.title, event.title)
        XCTAssertEqual(loaded.targetDate, event.targetDate)
        XCTAssertEqual(loaded.themeRawValue, event.themeRawValue)
    }

    @MainActor
    func testChangingImageBackgroundToGradientClearsItsImageReference() throws {
        let container = try makeMemoryContainer()
        let event = makeCountdown()
        event.appearance = CountdownAppearance(backgroundKind: .sample, imageName: "BackgroundCoast")
        container.mainContext.insert(event)
        try container.mainContext.save()

        var appearance = event.appearance
        appearance.backgroundKind = .gradient
        event.appearance = appearance
        try container.mainContext.save()

        let loaded = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<CountdownEntity>()).first)
        XCTAssertEqual(loaded.appearance.backgroundKind, .gradient)
        XCTAssertNil(loaded.backgroundImageName)
    }

    @MainActor
    func testLegacyDiskStoreMigratesWithoutLosingCountdownData() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("LegacyCountdown.store")
        let identifier = UUID()
        let date = Date(timeIntervalSince1970: 1_850_000_000)

        let legacySchema = Schema(LegacyCountdownSchema.models)
        let currentSchema = Schema([CountdownEntity.self])
        // SwiftData must resolve the nested legacy type to the same stored entity name.
        XCTAssertEqual(legacySchema.entities.map(\.name), currentSchema.entities.map(\.name))

        try autoreleasepool {
            let configuration = ModelConfiguration("MigrationTest", schema: legacySchema, url: storeURL, cloudKitDatabase: .none)
            let container = try ModelContainer(for: legacySchema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(LegacyCountdownSchema.CountdownEntity(id: identifier, targetDate: date))
            try context.save()
        }

        let configuration = ModelConfiguration("MigrationTest", schema: currentSchema, url: storeURL, cloudKitDatabase: .none)
        let container = try ModelContainer(for: currentSchema, configurations: [configuration])
        let loaded = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<CountdownEntity>()).first)

        XCTAssertEqual(loaded.id, identifier)
        XCTAssertEqual(loaded.title, "Legacy holiday")
        XCTAssertEqual(loaded.targetDate, date)
        XCTAssertEqual(loaded.theme, .sunset)
        XCTAssertEqual(loaded.widgetStyle, .compact)
        XCTAssertEqual(loaded.repeatRule, .yearly)
        XCTAssertEqual(loaded.location, "Auckland")
        XCTAssertEqual(loaded.notes, "Existing notes")
        XCTAssertNil(loaded.backgroundKindRawValue)
        XCTAssertNil(loaded.backgroundImageName)
        XCTAssertNil(loaded.textColorHex)
        XCTAssertEqual(loaded.appearance, CountdownAppearance())
    }

    @MainActor
    func testImageBackgroundDefaultsToWhiteAndHonorsCustomColor() {
        let photo = CountdownAppearance(backgroundKind: .photo, imageName: "photo.jpg")
        XCTAssertEqual(photo.foregroundColor(default: .black).hexRGB, "FFFFFF")

        let sample = CountdownAppearance(backgroundKind: .sample, imageName: "BackgroundCoast", textColorHex: "123ABC")
        XCTAssertEqual(sample.foregroundColor(default: .white).hexRGB, "123ABC")

        let gradient = CountdownAppearance(textColorHex: "FEDCBA")
        XCTAssertEqual(gradient.foregroundColor(default: .black).hexRGB, "FEDCBA")
    }

    @MainActor
    func testHexRGBSupportsGrayscaleAndCustomColorRoundTrips() {
        XCTAssertEqual(Color.white.hexRGB, "FFFFFF")
        XCTAssertEqual(Color.black.hexRGB, "000000")
        for hex in ["2A7CBF", "0011FF", "AABBCC", "808080", "FFFFFF", "000000"] {
            XCTAssertEqual(Color(hex: hex).hexRGB, hex)
        }
        XCTAssertTrue(Color.isValidHexRGB("abcdef"))
        XCTAssertFalse(Color.isValidHexRGB("#ABCDEF"))
        XCTAssertFalse(Color.isValidHexRGB("ABCDE"))
        XCTAssertFalse(Color.isValidHexRGB("GG0000"))
    }

    @MainActor
    func testAspectFillPreservesPortraitLandscapeAndMatchingAspect() {
        let container = CGSize(width: 300, height: 200)
        assertSize(
            CountdownImageLayout.renderedSize(imageSize: CGSize(width: 1200, height: 2400), containerSize: container, scale: 1),
            equals: CGSize(width: 300, height: 600)
        )
        assertSize(
            CountdownImageLayout.renderedSize(imageSize: CGSize(width: 2400, height: 1200), containerSize: container, scale: 1),
            equals: CGSize(width: 400, height: 200)
        )
        assertSize(
            CountdownImageLayout.renderedSize(imageSize: CGSize(width: 1500, height: 1000), containerSize: container, scale: 1),
            equals: container
        )
    }

    @MainActor
    func testImageZoomAndPositionClampInvalidAndOutOfRangeValues() {
        let size = CGSize(width: 200, height: 200)
        for scale in [-1.0, 0, 0.5, Double.nan, Double.infinity] {
            assertSize(CountdownImageLayout.renderedSize(imageSize: size, containerSize: size, scale: scale), equals: size)
        }
        assertSize(CountdownImageLayout.renderedSize(imageSize: size, containerSize: size, scale: 2), equals: CGSize(width: 400, height: 400))
        assertSize(CountdownImageLayout.renderedSize(imageSize: size, containerSize: size, scale: 9), equals: CGSize(width: 600, height: 600))
        assertSize(CountdownImageLayout.renderedSize(imageSize: .zero, containerSize: size, scale: 1), equals: size)

        XCTAssertEqual(CountdownImageLayout.clampedPosition(-4), 0)
        XCTAssertEqual(CountdownImageLayout.clampedPosition(4), 1)
        XCTAssertEqual(CountdownImageLayout.clampedPosition(0.25), 0.25)
        XCTAssertEqual(CountdownImageLayout.clampedPosition(.nan), 0.5)
        XCTAssertEqual(CountdownImageLayout.clampedPosition(.infinity), 0.5)
    }

    @MainActor
    func testPhotoPreparationDownsamplesLargePortraitAndPreservesAspect() async throws {
        let input = try XCTUnwrap(testImage(size: CGSize(width: 1200, height: 2400)).jpegData(compressionQuality: 0.9))
        let prepared = try await CountdownImageStore.preparePhoto(data: input)
        let image = try XCTUnwrap(UIImage(data: prepared))
        let pixels = pixelSize(of: image)

        XCTAssertLessThanOrEqual(max(pixels.width, pixels.height), 1600)
        XCTAssertEqual(pixels.width / pixels.height, 0.5, accuracy: 0.002)
        XCTAssertEqual(pixels.height, 1600, accuracy: 1)
        XCTAssertEqual(image.imageOrientation, .up)
    }

    @MainActor
    func testPhotoPreparationAppliesJPEGOrientationBeforeDownsampling() async throws {
        let original = testImage(size: CGSize(width: 2400, height: 1200))
        let cgImage = try XCTUnwrap(original.cgImage)
        let orientedJPEG = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(orientedJPEG, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, cgImage, [kCGImagePropertyOrientation: 6] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))

        let prepared = try await CountdownImageStore.preparePhoto(data: orientedJPEG as Data)
        let image = try XCTUnwrap(UIImage(data: prepared))
        let pixels = pixelSize(of: image)

        XCTAssertEqual(image.imageOrientation, .up)
        XCTAssertEqual(pixels.width / pixels.height, 0.5, accuracy: 0.002)
        XCTAssertLessThanOrEqual(max(pixels.width, pixels.height), 1600)
    }

    @MainActor
    func testPhotoPreparationRejectsInvalidData() async {
        for data in [Data(), Data("This is not an image".utf8)] {
            do {
                _ = try await CountdownImageStore.preparePhoto(data: data)
                XCTFail("Invalid photo data should throw")
            } catch CountdownImageStore.PhotoError.invalidImage {
                // Expected: importing malformed data must not create a persisted photo.
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    @MainActor
    func testPhotoFilesCanBeSavedLoadedAndRemovedIncludingCachedImage() throws {
        let data = try XCTUnwrap(testImage(size: CGSize(width: 320, height: 160)).jpegData(compressionQuality: 0.9))
        let name = try CountdownImageStore.savePhoto(data: data)
        defer { CountdownImageStore.removePhoto(named: name) }

        XCTAssertNotNil(UUID(uuidString: String(name.dropLast(4))))
        XCTAssertTrue(name.hasSuffix(".jpg"))
        let image = try XCTUnwrap(CountdownImageStore.image(named: name, kind: .photo))
        assertSize(pixelSize(of: image), equals: CGSize(width: 320, height: 160))
        // A second read exercises the cache; deletion must evict it as well as the file.
        XCTAssertNotNil(CountdownImageStore.image(named: name, kind: .photo))
        CountdownImageStore.removePhoto(named: name)
        XCTAssertNil(CountdownImageStore.image(named: name, kind: .photo))
    }

    @MainActor
    func testPhotoStoreRejectsPathTraversalAndUnknownNames() {
        let generatedName = "\(UUID().uuidString).jpg"
        for name in ["../\(generatedName)", "/tmp/\(generatedName)", "subdirectory/\(generatedName)", "not-a-uuid.jpg", "\(UUID().uuidString).png"] {
            XCTAssertNil(CountdownImageStore.image(named: name, kind: .photo))
        }
    }

    @MainActor
    func testBundledSamplesAndAllCardStylesRenderWithCustomTextColors() throws {
        let customColors = ["FFFFFF", "FFDE83", "C6FFEE"]
        var fixtures: [CardRenderingFixture] = []
        for (index, sample) in CountdownBackgroundSample.allCases.enumerated() {
            let image = try XCTUnwrap(CountdownImageStore.image(named: sample.imageName, kind: .sample), "Missing bundled sample: \(sample.imageName)")
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)

            let event = makeCountdown()
            event.title = "\(sample.title) getaway"
            let color = customColors[index % customColors.count]
            event.appearance = CountdownAppearance(
                backgroundKind: .sample,
                imageName: sample.imageName,
                textColorHex: color,
                dimAmount: 0.35
            )
            fixtures.append(CardRenderingFixture(event: event, label: "\(sample.title) · text #\(color)"))
        }
        let legacy = makeCountdown()
        fixtures.append(CardRenderingFixture(event: legacy, label: "Existing gradient · default text"))

        let now = Date(timeIntervalSince1970: 1_847_408_000)
        let content = VStack(alignment: .leading, spacing: 24) {
            Text("Countdown background and text previews")
                .font(.title2.weight(.bold))
            ForEach(fixtures) { fixture in
                CardRenderingPreviewRow(fixture: fixture, now: now)
            }
        }
        .padding(24)
        .frame(width: 870)
        .foregroundStyle(Color.primary)
        .background(Color(.systemGroupedBackground))
        .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        let screenshot = try XCTUnwrap(renderer.uiImage)
        XCTAssertGreaterThan(screenshot.size.height, 800)
        let attachment = XCTAttachment(image: screenshot)
        attachment.name = "Sample backgrounds, custom colors, and all card styles"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func makeMemoryContainer() throws -> ModelContainer {
        let schema = Schema([CountdownEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    private func makeCountdown() -> CountdownEntity {
        CountdownEntity(
            iconName: "airplane",
            categoryRawValue: "trip",
            targetDate: Date(timeIntervalSince1970: 1_850_000_000),
            themeRawValue: "sunset",
            title: "Holiday"
        )
    }

    @MainActor
    private func testImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height / 2))
        }
    }

    @MainActor
    private func pixelSize(of image: UIImage) -> CGSize {
        CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }

    @MainActor
    private func assertSize(_ actual: CGSize, equals expected: CGSize, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.width, expected.width, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actual.height, expected.height, accuracy: 0.001, file: file, line: line)
    }
}

private struct CardRenderingFixture: Identifiable {
    let id = UUID()
    let event: CountdownEntity
    let label: String
}

@MainActor
private struct CardRenderingPreviewRow: View {
    let fixture: CardRenderingFixture
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(fixture.label)
                .font(.headline)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Classic").font(.caption)
                    SimpleCountdownCard(event: fixture.event, style: .classic, now: now)
                        .frame(width: 300)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compact").font(.caption)
                    SimpleCountdownCard(event: fixture.event, style: .compact, now: now)
                        .frame(width: 300)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grid").font(.caption)
                    SimpleCountdownCard(event: fixture.event, style: .grid, now: now)
                        .frame(width: 190, height: 210)
                }
            }
        }
    }
}

// This is the released schema, before background/text customization fields were added.
private enum LegacyCountdownSchema: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    nonisolated static var models: [any PersistentModel.Type] { [CountdownEntity.self] }

    @Model
    final class CountdownEntity {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var iconName: String
        var isAllDay: Bool
        var isCompleted: Bool
        var location: String
        var notes: String
        var categoryRawValue: String
        var repeatRuleRawValue: String?
        var targetDate: Date
        var themeRawValue: String
        var title: String
        var widgetStyleRawValue: String?

        init(id: UUID, targetDate: Date) {
            self.id = id
            self.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
            self.iconName = "airplane"
            self.isAllDay = true
            self.isCompleted = false
            self.location = "Auckland"
            self.notes = "Existing notes"
            self.categoryRawValue = "trip"
            self.repeatRuleRawValue = "yearly"
            self.targetDate = targetDate
            self.themeRawValue = "sunset"
            self.title = "Legacy holiday"
            self.widgetStyleRawValue = "compact"
        }
    }
}
