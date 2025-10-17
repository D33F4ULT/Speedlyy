//
//  TripSummaryView.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import SwiftUI
import UIKit

struct TripSummaryView: View {
    @EnvironmentObject private var model: SpeedometerModel
    @Environment(\.dismiss) private var dismiss
    
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 64))
                            .foregroundStyle(.green)
                        
                        Text("Trip Summary")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        
                        if model.currentTrip.isActive {
                            Text("Active Trip")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.2), in: Capsule())
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        
                        TripSummaryCard(
                            icon: "speedometer",
                            title: "Max Speed",
                            value: "\(Int(maxSpeed))",
                            unit: model.settings.speedUnit.shortName,
                            color: .red
                        )
                        
                        TripSummaryCard(
                            icon: "gauge.with.dots.needle.50percent",
                            title: "Average Speed",
                            value: "\(Int(avgSpeed))",
                            unit: model.settings.speedUnit.shortName,
                            color: .blue
                        )
                        
                        TripSummaryCard(
                            icon: "point.topleft.down.to.point.bottomright.curvepath",
                            title: "Distance",
                            value: String(format: "%.2f", distance),
                            unit: model.settings.speedUnit.distanceUnit,
                            color: .green
                        )
                        
                        TripSummaryCard(
                            icon: "clock",
                            title: "Duration",
                            value: formatDuration(model.currentTrip.duration),
                            unit: "",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Additional Info
                    if model.currentTrip.speedSamples.count > 0 {
                        VStack(spacing: 16) {
                            Text("Trip Details")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                DetailRow(
                                    label: "Speed Samples",
                                    value: "\(model.currentTrip.speedSamples.count)"
                                )
                                
                                if let startTime = model.currentTrip.startTime {
                                    DetailRow(
                                        label: "Started",
                                        value: formatStartTime(startTime)
                                    )
                                }
                            }
                            .padding()
                            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                    
                    // Actions
                    VStack(spacing: 16) {
                        // Share Trip Button
                        Button {
                            shareTrip()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Trip Data")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                        }
                        
                        // Reset Trip Button
                        if model.currentTrip.duration > 0 {
                            Button {
                                resetTripWithConfirmation()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset Trip")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.black)
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
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func shareTrip() {
        let speedUnit = model.settings.speedUnit.shortName
        let distanceUnit = model.settings.speedUnit.distanceUnit
        
        let text = """
        🚗 Speedly Trip Summary
        
        Max Speed: \(Int(maxSpeed)) \(speedUnit)
        Average Speed: \(Int(avgSpeed)) \(speedUnit)
        Distance: \(String(format: "%.2f", distance)) \(distanceUnit)
        Duration: \(formatDuration(model.currentTrip.duration))
        
        Tracked with Speedly GPS Speedometer
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func resetTripWithConfirmation() {
        // Simple reset for now - in a production app you might want a confirmation alert
        model.resetTrip()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Supporting Views

struct TripSummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(.white)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    TripSummaryView()
        .environmentObject(SpeedometerModel())
}