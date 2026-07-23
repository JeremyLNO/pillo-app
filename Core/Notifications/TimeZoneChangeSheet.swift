import SwiftUI

/// Shown once when `RootView` detects the device timezone/DST offset changed since last
/// launch (spec section 16). Never silently shifts the interval between two doses —
/// the user always chooses explicitly.
struct TimeZoneChangeSheet: View {
    let onChoose: (TimeZoneChangeStrategy) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 44))
                .foregroundStyle(Palette.primary)
            Text("timezone.sheet.title")
                .font(Typography.title)
                .multilineTextAlignment(.center)
            Text("timezone.sheet.message")
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                PrimaryButton(title: String(localized: "timezone.sheet.keepLocalTime")) {
                    onChoose(.alwaysKeepLocalTime)
                }
                SecondaryButton(title: String(localized: "timezone.sheet.keepElapsedInterval")) {
                    onChoose(.alwaysKeepElapsedInterval)
                }
            }
        }
        .padding(28)
        .interactiveDismissDisabled()
    }
}

#Preview {
    TimeZoneChangeSheet(onChoose: { _ in })
}
