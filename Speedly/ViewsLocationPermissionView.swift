//
//  LocationPermissionView.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @EnvironmentObject private var model: SpeedometerModel
    @State private var debugInfo = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 80))
                .foregroundStyle(iconColor)
            
            // Title and Description
            VStack(spacing: 16) {
                Text("Location Access Required")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(permissionDescription)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Debug info (remove in production)
                if !debugInfo.isEmpty {
                    Text("Debug: \(debugInfo)")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Action Button
            Button(action: handlePermissionAction) {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            updateDebugInfo()
        }
        .onChange(of: model.locationAuthorizationStatus) { _, _ in
            updateDebugInfo()
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch model.locationAuthorizationStatus {
        case .notDetermined: return "location.circle"
        case .denied, .restricted: return "location.slash"
        case .authorizedWhenInUse, .authorizedAlways: return "location.circle.fill"
        @unknown default: return "location.circle"
        }
    }
    
    private var iconColor: Color {
        switch model.locationAuthorizationStatus {
        case .notDetermined: return .blue
        case .denied, .restricted: return .red
        case .authorizedWhenInUse, .authorizedAlways: return .green
        @unknown default: return .blue
        }
    }
    
    private var permissionDescription: String {
        switch model.locationAuthorizationStatus {
        case .notDetermined:
            return "Speedly needs access to your location to display accurate speed data. All location data stays on your device and is never shared."
            
        case .denied, .restricted:
            return "Location access is currently disabled. Please enable location services for Speedly in Settings to use the speedometer."
            
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location access is granted. The speedometer will start automatically."
            
        @unknown default:
            return "Location access is required to use the speedometer functionality."
        }
    }
    
    private var buttonTitle: String {
        switch model.locationAuthorizationStatus {
        case .notDetermined:
            return "Enable Location Access"
            
        case .denied, .restricted:
            return "Open Settings"
            
        case .authorizedWhenInUse, .authorizedAlways:
            return "Start Speedometer"
            
        @unknown default:
            return "Enable Location Access"
        }
    }
    
    // MARK: - Actions
    
    private func updateDebugInfo() {
        debugInfo = "Status: \(model.locationAuthorizationStatus)"
    }
    
    private func handlePermissionAction() {
        print("Permission button tapped. Current status: \(model.locationAuthorizationStatus)")
        
        switch model.locationAuthorizationStatus {
        case .notDetermined:
            print("Requesting location permission...")
            model.requestLocationPermission()
            
        case .denied, .restricted:
            print("Opening settings...")
            openAppSettings()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // This shouldn't normally happen as the view should switch automatically
            print("Already authorized, this shouldn't happen")
            break
            
        @unknown default:
            print("Unknown status, requesting permission...")
            model.requestLocationPermission()
        }
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
}

#Preview {
    LocationPermissionView()
        .environmentObject(SpeedometerModel())
}