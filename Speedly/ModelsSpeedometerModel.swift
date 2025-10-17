//
//  SpeedometerModel.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import Foundation
import SwiftUI
import AudioToolbox
import CoreLocation
import Combine

final class SpeedometerModel: ObservableObject {
    // MARK: - Services
    @ObservedObject private var locationService = LocationService()
    @ObservedObject private var speedLimitService = SpeedLimitService()
    
    // MARK: - User Settings
    @ObservedObject var settings = UserSettings()
    
    // MARK: - Trip Data
    @ObservedObject var currentTrip = TripData()
    
    // MARK: - Published Properties that trigger UI updates
    @Published var needsUpdate = false // Helper to trigger view updates
    
    // MARK: - Computed Properties
    var currentSpeed: Double {
        settings.speedUnit.convert(speedInMph: locationService.currentSpeed)
    }
    
    var speedUnit: String {
        settings.speedUnit.shortName
    }
    
    var currentSpeedLimit: Int? {
        guard let limitInfo = speedLimitService.currentSpeedLimit else {
            return settings.manualSpeedLimit > 0 ? settings.manualSpeedLimit : nil
        }
        
        // If we have a manual limit, prefer it
        if settings.manualSpeedLimit > 0 {
            return settings.manualSpeedLimit
        }
        
        return limitInfo.convertedLimit(for: settings.speedUnit)
    }
    
    var speedLimitSource: String? {
        if settings.manualSpeedLimit > 0 {
            return "Manual"
        }
        return speedLimitService.currentSpeedLimit?.source.displayName
    }
    
    var isExceedingSpeedLimit: Bool {
        guard let limit = currentSpeedLimit else { return false }
        return currentSpeed > Double(limit)
    }
    
    var speedExceedanceRatio: Double {
        guard let limit = currentSpeedLimit, limit > 0 else { return 0 }
        let excess = (currentSpeed - Double(limit)) / Double(limit)
        return min(max(excess, 0), 1.0)
    }
    
    var speedColor: Color {
        settings.colorTheme.color(
            for: currentSpeed,
            speedLimit: currentSpeedLimit,
            isExceeding: isExceedingSpeedLimit
        )
    }
    
    var gpsAccuracy: GPSAccuracy? {
        locationService.gpsAccuracy
    }
    
    var locationInfo: LocationInfo? {
        locationService.locationInfo
    }
    
    var isLocationAuthorized: Bool {
        locationService.authorizationStatus.isAuthorized
    }
    
    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var lastExceedingState = false
    private var lastLocation: CLLocation?
    private var speedLimitUpdateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init() {
        setupObservation()
        
        // Set up bindings to observe changes in services
        locationService.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        speedLimitService.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        settings.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        currentTrip.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func startTrip() {
        currentTrip.start()
    }
    
    func stopTrip() {
        currentTrip.stop()
    }
    
    func resetTrip() {
        currentTrip.reset()
        if currentTrip.isActive {
            currentTrip.start()
        }
    }
    
    func setManualSpeedLimit(_ limit: Int) {
        settings.manualSpeedLimit = limit
        speedLimitService.setManualSpeedLimit(limit)
    }
    
    func clearManualSpeedLimit() {
        settings.manualSpeedLimit = 0
        speedLimitService.clearManualSpeedLimit()
    }
    
    // MARK: - Private Methods
    private func setupObservation() {
        // Start observing location updates
        startLocationObservation()
        
        // Start trip automatically when location is available
        if isLocationAuthorized {
            startTrip()
        }
    }
    
    private func startLocationObservation() {
        // This would be better with proper observation in a real implementation
        // For now, we'll use a timer to check for updates
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.handleLocationUpdate()
        }
    }
    
    private func handleLocationUpdate() {
        guard let location = locationService.currentLocation else { return }
        
        // Update trip data
        updateTripData(with: location)
        
        // Update speed limit if needed
        updateSpeedLimitIfNeeded(for: location)
        
        // Handle speed limit alerts
        handleSpeedLimitAlerts()
        
        lastLocation = location
    }
    
    private func updateTripData(with location: CLLocation) {
        guard currentTrip.isActive else { return }
        
        let currentSpeedMph = locationService.currentSpeed
        
        // Update trip with current speed
        if currentSpeedMph > 1.0 { // Only count meaningful speeds
            currentTrip.addSpeedSample(currentSpeedMph)
        }
        
        // Calculate distance
        if let lastLoc = lastLocation {
            let distance = location.distance(from: lastLoc)
            let distanceInMiles = distance * 0.000621371
            
            // Only add distance if it's reasonable (not GPS jitter)
            if distanceInMiles > 0.001 && distanceInMiles < 0.1 && currentSpeedMph > 1.0 {
                currentTrip.addDistance(distanceInMiles)
            }
        }
        
        // Update duration
        currentTrip.updateDuration()
    }
    
    private func updateSpeedLimitIfNeeded(for location: CLLocation) {
        // Cancel previous task
        speedLimitUpdateTask?.cancel()
        
        // Start new task
        speedLimitUpdateTask = Task {
            await speedLimitService.updateSpeedLimit(for: location)
        }
    }
    
    private func handleSpeedLimitAlerts() {
        guard settings.speedLimitAlerts else { return }
        
        let isCurrentlyExceeding = isExceedingSpeedLimit
        
        // Only alert when starting to exceed (not continuously)
        if isCurrentlyExceeding && !lastExceedingState {
            triggerSpeedLimitAlert()
        }
        
        lastExceedingState = isCurrentlyExceeding
    }
    
    private func triggerSpeedLimitAlert() {
        // Haptic feedback
        if settings.enableHaptics {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        
        // Sound alert
        if settings.enableSoundAlerts {
            AudioServicesPlaySystemSound(1053) // System sound
        }
    }
    
    deinit {
        speedLimitUpdateTask?.cancel()
    }
}