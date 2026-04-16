import SwiftUI

extension View {
    func appPageWidth() -> some View {
        frame(maxWidth: 920)
            .frame(maxWidth: .infinity)
    }
}
