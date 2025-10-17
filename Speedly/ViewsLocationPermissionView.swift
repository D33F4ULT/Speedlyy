//
//  LocationPermissionView.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @Environment(SpeedometerModel.self) private var model
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
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
    }
    
    // MARK: - Computed Properties
    
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
    
    private func handlePermissionAction() {
        switch model.locationAuthorizationStatus {
        case .notDetermined:
            model.requestLocationPermission()
            
        case .denied, .restricted:
            openAppSettings()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // This shouldn't normally happen as the view should switch automatically
            // But we can handle it gracefully
            break
            
        @unknown default:
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
        .environment(SpeedometerModel())
}