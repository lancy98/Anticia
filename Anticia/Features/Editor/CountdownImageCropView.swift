import SwiftUI
import UIKit

struct CountdownImageCropView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var appearance: CountdownAppearance
    @State private var workingAppearance: CountdownAppearance
    @State private var dragStart: CGPoint?

    let event: CountdownEntity
    let style: CountdownWidgetStyle
    let image: UIImage

    init(
        appearance: Binding<CountdownAppearance>,
        event: CountdownEntity,
        style: CountdownWidgetStyle,
        image: UIImage
    ) {
        _appearance = appearance
        _workingAppearance = State(initialValue: appearance.wrappedValue)
        self.event = event
        self.style = style
        self.image = image
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("appearance.dragHint")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    SimpleCountdownCard(
                        event: event,
                        style: style,
                        now: .now,
                        appearanceOverride: workingAppearance,
                        previewImage: image
                    )
                    .frame(width: style == .grid ? 180 : nil, height: style == .grid ? 210 : nil)
                    .overlay {
                        GeometryReader { proxy in
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(repositionGesture(in: proxy.size))
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("appearance.zoom")
                                Spacer()
                                Text(workingAppearance.imageScale, format: .number.precision(.fractionLength(1)))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: $workingAppearance.imageScale, in: 1...3)
                                .accessibilityLabel(Text("appearance.zoom"))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("appearance.horizontalPosition")
                            Slider(value: $workingAppearance.imagePositionX, in: 0...1)
                                .accessibilityLabel(Text("appearance.horizontalPosition"))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("appearance.verticalPosition")
                            Slider(value: $workingAppearance.imagePositionY, in: 0...1)
                                .accessibilityLabel(Text("appearance.verticalPosition"))
                        }

                        Button(String(localized: "appearance.resetPosition")) {
                            workingAppearance.imageScale = 1
                            workingAppearance.imagePositionX = 0.5
                            workingAppearance.imagePositionY = 0.5
                        }
                    }
                    .padding(20)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(24)
            }
            .navigationTitle(String(localized: "appearance.reposition"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: L10n.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "appearance.done")) {
                        appearance = workingAppearance
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func repositionGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = CGPoint(
                        x: workingAppearance.imagePositionX,
                        y: workingAppearance.imagePositionY
                    )
                }
                guard let dragStart else { return }
                let renderedSize = CountdownImageLayout.renderedSize(
                    imageSize: image.size,
                    containerSize: size,
                    scale: workingAppearance.imageScale
                )
                let horizontalOverflow = max(0, renderedSize.width - size.width)
                let verticalOverflow = max(0, renderedSize.height - size.height)

                if horizontalOverflow > 0 {
                    workingAppearance.imagePositionX = min(
                        1,
                        max(0, dragStart.x - value.translation.width / horizontalOverflow)
                    )
                }
                if verticalOverflow > 0 {
                    workingAppearance.imagePositionY = min(
                        1,
                        max(0, dragStart.y - value.translation.height / verticalOverflow)
                    )
                }
            }
            .onEnded { _ in dragStart = nil }
    }
}
