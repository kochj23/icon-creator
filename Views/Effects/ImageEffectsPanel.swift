import SwiftUI

/// Panel for configuring advanced image effects
struct ImageEffectsPanel: View {
    @Binding var effects: ImageEffects
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("Advanced Effects")
                        .font(.headline)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Corner Radius
                    EffectSection(title: "Corner Radius", isEnabled: $effects.cornerRadiusEnabled) {
                        HStack {
                            Slider(value: $effects.cornerRadius, in: 0...50)
                            Text("\(Int(effects.cornerRadius))%")
                                .frame(width: 40)
                                .font(.caption)
                        }
                    }

                    Divider()

                    // Drop Shadow
                    EffectSection(title: "Drop Shadow", isEnabled: $effects.shadowEnabled) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Blur:")
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $effects.shadowBlur, in: 0...50)
                                Text("\(Int(effects.shadowBlur))")
                                    .frame(width: 40)
                                    .font(.caption)
                            }

                            HStack {
                                Text("Offset X:")
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $effects.shadowOffsetX, in: -20...20)
                                Text("\(Int(effects.shadowOffsetX))")
                                    .frame(width: 40)
                                    .font(.caption)
                            }

                            HStack {
                                Text("Offset Y:")
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $effects.shadowOffsetY, in: -20...20)
                                Text("\(Int(effects.shadowOffsetY))")
                                    .frame(width: 40)
                                    .font(.caption)
                            }

                            ColorPicker("Color", selection: Binding(
                                get: { effects.shadowColor.color },
                                set: { effects.shadowColor = ColorComponents($0) }
                            ))
                            .frame(width: 200)
                        }
                    }

                    Divider()

                    // Border
                    EffectSection(title: "Border", isEnabled: $effects.borderEnabled) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Width:")
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $effects.borderWidth, in: 1...20)
                                Text("\(Int(effects.borderWidth))")
                                    .frame(width: 40)
                                    .font(.caption)
                            }

                            ColorPicker("Color", selection: Binding(
                                get: { effects.borderColor.color },
                                set: { effects.borderColor = ColorComponents($0) }
                            ))
                            .frame(width: 200)
                        }
                    }

                    Divider()

                    // Background Type
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Background")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Picker("Type", selection: Binding(
                            get: {
                                switch effects.backgroundType {
                                case .solid: return 0
                                case .gradient: return 1
                                case .transparent: return 2
                                }
                            },
                            set: { newValue in
                                switch newValue {
                                case 0: effects.backgroundType = .solid
                                case 1: effects.backgroundType = .gradient(.sunset, .vertical)
                                case 2: effects.backgroundType = .transparent
                                default: break
                                }
                            }
                        )) {
                            Text("Solid").tag(0)
                            Text("Gradient").tag(1)
                            Text("Transparent").tag(2)
                        }
                        .pickerStyle(.segmented)

                        // Gradient controls
                        if case .gradient(let gradient, let direction) = effects.backgroundType {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Direction", selection: Binding(
                                    get: { direction },
                                    set: { newDirection in
                                        if case .gradient(let g, _) = effects.backgroundType {
                                            effects.backgroundType = .gradient(g, newDirection)
                                        }
                                    }
                                )) {
                                    Text("Vertical").tag(ImageEffects.GradientDirection.vertical)
                                    Text("Horizontal").tag(ImageEffects.GradientDirection.horizontal)
                                    Text("Diagonal").tag(ImageEffects.GradientDirection.diagonal)
                                    Text("Radial").tag(ImageEffects.GradientDirection.radial)
                                }
                                .pickerStyle(.menu)

                                // Preset gradients
                                HStack {
                                    Button("Sunset") {
                                        if case .gradient(_, let d) = effects.backgroundType {
                                            effects.backgroundType = .gradient(.sunset, d)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)

                                    Button("Ocean") {
                                        if case .gradient(_, let d) = effects.backgroundType {
                                            effects.backgroundType = .gradient(.ocean, d)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)

                                    Button("Forest") {
                                        if case .gradient(_, let d) = effects.backgroundType {
                                            effects.backgroundType = .gradient(.forest, d)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }

                    Divider()

                    // Image Adjustments
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Image Adjustments")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Text("Brightness:")
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $effects.brightness, in: -1...1)
                            Text(String(format: "%.2f", effects.brightness))
                                .frame(width: 50)
                                .font(.caption)
                        }

                        HStack {
                            Text("Contrast:")
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $effects.contrast, in: -1...1)
                            Text(String(format: "%.2f", effects.contrast))
                                .frame(width: 50)
                                .font(.caption)
                        }

                        HStack {
                            Text("Saturation:")
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $effects.saturation, in: -1...1)
                            Text(String(format: "%.2f", effects.saturation))
                                .frame(width: 50)
                                .font(.caption)
                        }
                    }

                    // Reset button
                    Button("Reset All Effects") {
                        effects = ImageEffects()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Effect Section

struct EffectSection<Content: View>: View {
    let title: String
    @Binding var isEnabled: Bool
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(title, isOn: $isEnabled)
                .font(.subheadline)
                .fontWeight(.medium)

            if isEnabled {
                content()
                    .padding(.leading, 20)
            }
        }
    }
}
