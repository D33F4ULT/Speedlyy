//
//  SettingsView.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: SpeedometerModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Display Settings
                    SettingsSection("Display") {
                        VStack(spacing: 16) {
                            // Speed Unit Toggle
                            SettingRow(
                                icon: "speedometer",
                                title: "Speed Unit",
                                content: {
                                    Picker("Speed Unit", selection: Binding(
                                        get: { model.settings.speedUnit },
                                        set: { model.settings.speedUnit = $0 }
                                    )) {
                                        ForEach(SpeedUnit.allCases, id: \.self) { unit in
                                            Text(unit.displayName).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            )
                            
                            // Show Street Name
                            SettingRow(
                                icon: "location.fill",
                                title: "Show Street Name"
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { model.settings.showStreetName },
                                    set: { model.settings.showStreetName = $0 }
                                ))
                                .tint(.blue)
                            }
                            
                            // Show Trip Stats
                            SettingRow(
                                icon: "chart.bar.fill",
                                title: "Show Trip Statistics"
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { model.settings.showTripStats },
                                    set: { model.settings.showTripStats = $0 }
                                ))
                                .tint(.blue)
                            }
                            
                            // Color Theme
                            SettingRow(
                                icon: "paintbrush.fill",
                                title: "Color Theme",
                                content: {
                                    Picker("Color Theme", selection: Binding(
                                        get: { model.settings.colorTheme },
                                        set: { model.settings.colorTheme = $0 }
                                    )) {
                                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                                            Text(theme.displayName).tag(theme)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            )
                        }
                    }
                    
                    // Alert Settings
                    SettingsSection("Alerts") {
                        VStack(spacing: 16) {
                            SettingRow(
                                icon: "speaker.wave.2.fill",
                                title: "Sound Alerts"
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { model.settings.enableSoundAlerts },
                                    set: { model.settings.enableSoundAlerts = $0 }
                                ))
                                .tint(.blue)
                            }
                            
                            SettingRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "Haptic Feedback"
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { model.settings.enableHaptics },
                                    set: { model.settings.enableHaptics = $0 }
                                ))
                                .tint(.blue)
                            }
                            
                            SettingRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Speed Limit Alerts"
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { model.settings.speedLimitAlerts },
                                    set: { model.settings.speedLimitAlerts = $0 }
                                ))
                                .tint(.blue)
                            }
                        }
                    }
                    
                    // Performance Settings
                    SettingsSection("Performance") {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                SettingRow(
                                    icon: "waveform.path",
                                    title: "Speed Smoothing"
                                ) {
                                    Text(smoothingLabel)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                
                                HStack {
                                    Image(systemName: "hare.fill")
                                        .foregroundStyle(.white.opacity(0.6))
                                        .font(.caption)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { model.settings.speedSmoothing },
                                            set: { newValue in
                                                model.settings.speedSmoothing = newValue
                                                // Update the location service
                                            }
                                        ),
                                        in: 0...1
                                    )
                                    .tint(.blue)
                                    
                                    Image(systemName: "tortoise.fill")
                                        .foregroundStyle(.white.opacity(0.6))
                                        .font(.caption)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Trip Management
                    SettingsSection("Trip") {
                        VStack(spacing: 16) {
                            Button {
                                model.resetTrip()
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset Current Trip")
                                    Spacer()
                                }
                                .foregroundStyle(.blue)
                                .padding()
                                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    
                    // About Section
                    SettingsSection("About") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Speedly uses GPS and motion sensors for accurate speed tracking. All data stays on your device and is never shared with third parties.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Text("Screen sleep is automatically disabled while the app is active to ensure continuous operation.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    private var smoothingLabel: String {
        let value = model.settings.speedSmoothing
        switch value {
        case 0..<0.2: return "Responsive"
        case 0.2..<0.5: return "Balanced"
        case 0.5..<0.8: return "Smooth"
        default: return "Very Smooth"
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            
            VStack(spacing: 0) {
                content()
            }
            .padding()
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let content: () -> Content
    
    init(
        icon: String,
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.content = content
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                
                content()
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SpeedometerModel())
}