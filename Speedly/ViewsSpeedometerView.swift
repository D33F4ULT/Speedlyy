//
//  SpeedometerView.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import SwiftUI

struct SpeedometerView: View {
    @Environment(SpeedometerModel.self) private var model
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var orientation = UIDevice.current.orientation
    
    private var isLandscape: Bool {
        orientation.isLandscape
    }
    
    private var isUpsideDown: Bool {
        orientation == .portraitUpsideDown || orientation == .landscapeRight
    }
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if isLandscape {
                    LandscapeSpeedometerView()
                } else {
                    PortraitSpeedometerView()
                }
            }
            .rotationEffect(.degrees(isUpsideDown ? 180 : 0))
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            withAnimation(.smooth(duration: 0.3)) {
                orientation = UIDevice.current.orientation
            }
        }
    }
}

// MARK: - Portrait Layout
struct PortraitSpeedometerView: View {
    @Environment(SpeedometerModel.self) private var model
    @State private var showSpeedLimitEditor = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 60)
                
                // Main Speed Display
                SpeedDisplayView()
                
                // Speed Limit Sign
                if let speedLimit = model.currentSpeedLimit {
                    SpeedLimitSignView(limit: speedLimit)
                        .onLongPressGesture {
                            showSpeedLimitEditor = true
                            hapticFeedback(.medium)
                        }
                } else if model.currentSpeed > 5 {
                    AddSpeedLimitButton {
                        showSpeedLimitEditor = true
                    }
                }
                
                // Information Cards
                InformationCardsView()
                
                // Trip Statistics
                if model.settings.showTripStats {
                    TripStatsView()
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showSpeedLimitEditor) {
            SpeedLimitEditorView()
                .environment(model)
        }
    }
}

// MARK: - Landscape Layout
struct LandscapeSpeedometerView: View {
    @Environment(SpeedometerModel.self) private var model
    @State private var speedSize: Double = 1.0
    @State private var showSpeedLimitEditor = false
    
    var body: some View {
        HStack {
            Spacer()
            
            // Main Speed Display
            SpeedDisplayView(sizeMultiplier: speedSize)
                .onTapGesture {
                    cycleSpeedSize()
                    hapticFeedback(.light)
                }
            
            Spacer()
        }
        .overlay(alignment: .topTrailing) {
            if let speedLimit = model.currentSpeedLimit {
                SpeedLimitSignView(limit: speedLimit, size: 70)
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                    .onLongPressGesture {
                        showSpeedLimitEditor = true
                        hapticFeedback(.medium)
                    }
            }
        }
        .sheet(isPresented: $showSpeedLimitEditor) {
            SpeedLimitEditorView()
                .environment(model)
        }
    }
    
    private func cycleSpeedSize() {
        let sizes: [Double] = [1.0, 1.25, 1.5, 1.75]
        let currentIndex = sizes.firstIndex(where: { abs($0 - speedSize) < 0.1 }) ?? 0
        let nextIndex = (currentIndex + 1) % sizes.count
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            speedSize = sizes[nextIndex]
        }
    }
}

// MARK: - Speed Display Component
struct SpeedDisplayView: View {
    @Environment(SpeedometerModel.self) private var model
    let sizeMultiplier: Double
    
    init(sizeMultiplier: Double = 1.0) {
        self.sizeMultiplier = sizeMultiplier
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(model.currentSpeed.rounded()))")
                .font(.system(
                    size: 120 * sizeMultiplier,
                    weight: .heavy,
                    design: .rounded
                ))
                .foregroundStyle(model.speedColor)
                .contentTransition(.numericText(value: model.currentSpeed))
                .animation(.smooth(duration: 0.15), value: model.currentSpeed)
                .animation(.easeInOut(duration: 0.3), value: model.speedColor)
                .shadow(color: model.speedColor.opacity(0.6), radius: glowRadius)
            
            Text(model.speedUnit)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.5))
                .offset(y: -10)
        }
    }
    
    private var glowRadius: CGFloat {
        if model.settings.colorTheme == .dynamic && model.isExceedingSpeedLimit {
            return 20 + (model.speedExceedanceRatio * 30)
        }
        return 0
    }
}

// MARK: - Speed Limit Sign
struct SpeedLimitSignView: View {
    let limit: Int
    let size: CGFloat
    
    init(limit: Int, size: CGFloat = 80) {
        self.limit = limit
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: size, height: size)
            
            Circle()
                .stroke(.red, lineWidth: size * 0.12)
                .frame(width: size * 0.88, height: size * 0.88)
            
            Text("\(limit)")
                .font(.system(
                    size: size * 0.45,
                    weight: .black,
                    design: .rounded
                ))
                .foregroundStyle(.black)
        }
        .shadow(color: .white.opacity(0.3), radius: 8)
        .accessibilityLabel("Speed limit \(limit)")
    }
}

// MARK: - Add Speed Limit Button
struct AddSpeedLimitButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.3))
                
                Text("Set Speed Limit")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding()
        }
    }
}

// MARK: - Information Cards
struct InformationCardsView: View {
    @Environment(SpeedometerModel.self) private var model
    
    var body: some View {
        VStack(spacing: 12) {
            if let locationInfo = model.locationInfo {
                if let street = locationInfo.streetName, model.settings.showStreetName {
                    InfoCardView(
                        icon: "location.fill",
                        title: "Street",
                        value: street,
                        status: .normal
                    )
                }
                
                if let city = locationInfo.cityName {
                    InfoCardView(
                        icon: "building.2.fill",
                        title: "City",
                        value: city,
                        status: .normal
                    )
                }
            }
            
            if let gpsAccuracy = model.gpsAccuracy {
                InfoCardView(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "GPS Accuracy",
                    value: gpsAccuracy.description,
                    status: gpsAccuracy.qualityLevel
                )
            }
            
            if let source = model.speedLimitSource {
                InfoCardView(
                    icon: "network",
                    title: "Speed Limit Source",
                    value: source,
                    status: .normal
                )
            }
        }
    }
}

struct InfoCardView: View {
    let icon: String
    let title: String
    let value: String
    let status: QualityLevel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(status.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Trip Stats
struct TripStatsView: View {
    @Environment(SpeedometerModel.self) private var model
    
    private var maxSpeed: Double {
        model.settings.speedUnit.convert(speedInMph: model.currentTrip.maxSpeed)
    }
    
    private var avgSpeed: Double {
        model.settings.speedUnit.convert(speedInMph: model.currentTrip.averageSpeed)
    }
    
    private var distance: Double {
        let miles = model.currentTrip.distance
        return model.settings.speedUnit.convertDistance(milesOrKm: miles)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
                
                Text("Trip Statistics")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            HStack(spacing: 20) {
                TripStatItem(
                    label: "MAX",
                    value: "\(Int(maxSpeed))",
                    unit: model.settings.speedUnit.shortName
                )
                
                TripStatItem(
                    label: "AVG",
                    value: "\(Int(avgSpeed))",
                    unit: model.settings.speedUnit.shortName
                )
                
                TripStatItem(
                    label: "DIST",
                    value: String(format: "%.1f", distance),
                    unit: model.settings.speedUnit.distanceUnit
                )
                
                TripStatItem(
                    label: "TIME",
                    value: formatDuration(model.currentTrip.duration),
                    unit: ""
                )
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TripStatItem: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.5)
            
            HStack(spacing: 3) {
                Text(value)
                    .font(.system(.callout, design: .rounded).monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.8))
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Helper Functions
private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

#Preview {
    SpeedometerView()
        .environment(SpeedometerModel())
}