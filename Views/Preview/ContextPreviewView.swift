import SwiftUI

/// Enhanced preview showing icons in realistic contexts
struct ContextPreviewView: View {
    let icon: NSImage
    @State private var selectedContext: PreviewContext = .allSizes
    @State private var selectedDevice: Device = .iPhone15Pro
    @State private var selectedAppearance: Appearance = .light

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            VStack(spacing: 12) {
                Text("Context Preview")
                    .font(.title2)
                    .bold()

                // Context selector
                Picker("Preview Type", selection: $selectedContext) {
                    ForEach(PreviewContext.allCases, id: \.self) { context in
                        Text(context.displayName).tag(context)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                // Device and appearance selectors (only for device mockups)
                if selectedContext.needsDeviceSelection {
                    HStack {
                        Picker("Device", selection: $selectedDevice) {
                            ForEach(Device.allCases, id: \.self) { device in
                                Text(device.displayName).tag(device)
                            }
                        }
                        .frame(width: 200)

                        Picker("Appearance", selection: $selectedAppearance) {
                            ForEach(Appearance.allCases, id: \.self) { appearance in
                                Label(appearance.displayName, systemImage: appearance.icon)
                                    .tag(appearance)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }
            }
            .padding()

            Divider()

            // Preview content
            ScrollView {
                previewContent
                    .padding()
            }
        }
        .frame(width: 800, height: 700)
    }

    @ViewBuilder
    private var previewContent: some View {
        switch selectedContext {
        case .allSizes:
            AllSizesPreview(icon: icon)
        case .homeScreen:
            HomeScreenPreview(icon: icon, device: selectedDevice, appearance: selectedAppearance)
        case .appStore:
            AppStorePreview(icon: icon)
        case .spotlight:
            SpotlightPreview(icon: icon, appearance: selectedAppearance)
        case .settings:
            SettingsPreview(icon: icon, appearance: selectedAppearance)
        case .notifications:
            NotificationPreview(icon: icon, appearance: selectedAppearance)
        case .actualSize:
            ActualSizePreview(icon: icon)
        }
    }
}

// MARK: - Preview Context Types

enum PreviewContext: String, CaseIterable {
    case allSizes = "All Sizes"
    case homeScreen = "Home Screen"
    case appStore = "App Store"
    case spotlight = "Spotlight"
    case settings = "Settings"
    case notifications = "Notifications"
    case actualSize = "Actual Size"

    var displayName: String { rawValue }

    var needsDeviceSelection: Bool {
        switch self {
        case .homeScreen, .spotlight, .settings, .notifications:
            return true
        default:
            return false
        }
    }
}

// MARK: - All Sizes Preview

struct AllSizesPreview: View {
    let icon: NSImage

    let sizes = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
            ForEach(sizes, id: \.self) { size in
                VStack(spacing: 8) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: CGFloat(min(size, 120)), height: CGFloat(min(size, 120)))
                        .cornerRadius(8)
                        .shadow(radius: 2)

                    Text("\(size)×\(size)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Home Screen Preview

struct HomeScreenPreview: View {
    let icon: NSImage
    let device: Device
    let appearance: Appearance

    var body: some View {
        VStack(spacing: 20) {
            Text("Home Screen Preview")
                .font(.headline)

            ZStack {
                // Background
                appearance.backgroundColor
                    .cornerRadius(device.screenCornerRadius)

                // Icon grid
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(80), spacing: 20), count: 4), spacing: 20) {
                    ForEach(0..<12, id: \.self) { index in
                        if index == 5 {
                            // Our icon (highlighted)
                            VStack(spacing: 4) {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(13)
                                    .shadow(radius: 2)

                                Text("My App")
                                    .font(.caption2)
                                    .foregroundColor(appearance.textColor)
                            }
                        } else {
                            // Placeholder apps
                            PlaceholderAppIcon(appearance: appearance)
                        }
                    }
                }
                .padding(40)
            }
            .frame(width: device.previewWidth, height: device.previewHeight)
            .overlay(
                RoundedRectangle(cornerRadius: device.screenCornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct PlaceholderAppIcon: View {
    let appearance: Appearance

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 13)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)

            Text("App")
                .font(.caption2)
                .foregroundColor(appearance.textColor.opacity(0.5))
        }
    }
}

// MARK: - App Store Preview

struct AppStorePreview: View {
    let icon: NSImage

    var body: some View {
        VStack(spacing: 20) {
            Text("App Store Preview")
                .font(.headline)

            HStack(spacing: 20) {
                // Large icon
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 120, height: 120)
                    .cornerRadius(26)
                    .shadow(radius: 5)

                // App info mockup
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Amazing App")
                        .font(.title2)
                        .bold()

                    Text("Make your life better")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        // Rating stars
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        Text("4.8")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button("GET") {
                        // Mock button
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Spacer()
            }
            .padding()
            .frame(width: 600)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Spotlight Preview

struct SpotlightPreview: View {
    let icon: NSImage
    let appearance: Appearance

    var body: some View {
        VStack(spacing: 20) {
            Text("Spotlight Search")
                .font(.headline)

            VStack(spacing: 12) {
                // Our app result
                HStack(spacing: 12) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("My App")
                            .font(.body)
                            .foregroundColor(appearance.textColor)

                        Text("Application")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(appearance == .dark ? Color.gray.opacity(0.2) : Color.white)
                .cornerRadius(12)

                // Other results (placeholders)
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Other App")
                                .font(.body)
                                .foregroundColor(appearance.textColor.opacity(0.5))

                            Text("Application")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(appearance == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .frame(width: 500)
            .padding()
            .background(appearance.backgroundColor)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Settings Preview

struct SettingsPreview: View {
    let icon: NSImage
    let appearance: Appearance

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings App")
                .font(.headline)

            VStack(spacing: 1) {
                // Our app row
                HStack {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 29, height: 29)
                        .cornerRadius(6)

                    Text("My App")
                        .font(.body)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(appearance == .dark ? Color.gray.opacity(0.2) : Color.white)

                Divider()

                // Other settings rows
                ForEach(0..<5, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 29, height: 29)

                        Text("Other Setting")
                            .font(.body)
                            .foregroundColor(appearance.textColor.opacity(0.5))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(appearance == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.05))

                    Divider()
                }
            }
            .frame(width: 400)
            .background(appearance.backgroundColor)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
    }
}

// MARK: - Notification Preview

struct NotificationPreview: View {
    let icon: NSImage
    let appearance: Appearance

    var body: some View {
        VStack(spacing: 20) {
            Text("Notification Banner")
                .font(.headline)

            HStack(spacing: 12) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MY APP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .bold()

                    Text("New notification from your app")
                        .font(.body)
                        .foregroundColor(appearance.textColor)

                    Text("Just now")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .frame(width: 500)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(appearance == .dark ? Color.gray.opacity(0.3) : Color.white)
                    .shadow(radius: 10)
            )
        }
    }
}

// MARK: - Actual Size Preview

struct ActualSizePreview: View {
    let icon: NSImage

    var body: some View {
        VStack(spacing: 20) {
            Text("Actual Size (1:1 pixels)")
                .font(.headline)

            Image(nsImage: icon)
                .resizable()
                .frame(width: icon.size.width, height: icon.size.height)
                .border(Color.gray.opacity(0.3), width: 1)

            Text("\(Int(icon.size.width))×\(Int(icon.size.height)) pixels")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Zoom: 100%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Types

enum Device: String, CaseIterable {
    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15ProMax = "iPhone 15 Pro Max"
    case iPadPro = "iPad Pro"
    case mac = "Mac"

    var displayName: String { rawValue }

    var previewWidth: CGFloat {
        switch self {
        case .iPhone15Pro: return 375
        case .iPhone15ProMax: return 430
        case .iPadPro: return 600
        case .mac: return 600
        }
    }

    var previewHeight: CGFloat {
        switch self {
        case .iPhone15Pro: return 500
        case .iPhone15ProMax: return 600
        case .iPadPro: return 600
        case .mac: return 500
        }
    }

    var screenCornerRadius: CGFloat {
        switch self {
        case .iPhone15Pro, .iPhone15ProMax: return 40
        case .iPadPro: return 20
        case .mac: return 10
        }
    }
}

enum Appearance: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .light: return Color(white: 0.95)
        case .dark: return Color(white: 0.15)
        }
    }

    var textColor: Color {
        switch self {
        case .light: return .black
        case .dark: return .white
        }
    }
}
