import SwiftUI
import UIKit

/// Capsule status label, 12 pt semibold. Text is always shown, so state is
/// never communicated by colour alone.
struct StatusPill: View {
    let status: JobDisplayStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status.fillColor, in: Capsule())
            .lineLimit(1)
            .fixedSize()
    }
}

extension JobDisplayStatus {
    /// Darker than the system colours in light mode so the text passes 4.5:1
    /// on its tinted background; lighter in dark mode for the same reason.
    var textColor: Color {
        switch self {
        case .pending: Color(light: 0x8A4B00, dark: 0xFFB340)
        case .inProgress: Color(light: 0x0050B3, dark: 0x6CB2FF)
        case .completed: Color(light: 0x1C6B2E, dark: 0x5DD879)
        case .overdue: Color(light: 0xB3001B, dark: 0xFF6B6B)
        case .unknown: .secondary
        }
    }

    var fillColor: Color {
        switch self {
        case .pending: Color.orange.opacity(0.16)
        case .inProgress: Color.blue.opacity(0.14)
        case .completed: Color.green.opacity(0.16)
        case .overdue: Color.red.opacity(0.13)
        case .unknown: Color.gray.opacity(0.16)
        }
    }
}

extension Color {
    /// A colour that adapts to light and dark mode.
    ///
    /// The maths is inline on purpose: UIKit may call the provider off the
    /// main actor, so it must not call app code that Xcode 26's default
    /// MainActor isolation would tie to the main actor.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusPill(status: .pending)
        StatusPill(status: .inProgress)
        StatusPill(status: .completed)
        StatusPill(status: .overdue)
        StatusPill(status: .unknown("on_hold"))
    }
    .padding()
}
