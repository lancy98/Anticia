import SwiftUI

struct CountdownRing: View {
    let progress: Double
    let primaryText: String
    let secondaryText: String
    let theme: CountdownTheme

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 16)

            Circle()
                .trim(from: 0, to: max(0.05, min(progress, 1)))
                .stroke(theme.gradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(primaryText)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                Text(secondaryText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 190, height: 190)
    }
}
