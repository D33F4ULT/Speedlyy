//
//  LocationService.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import Foundation
import CoreLocation
import Combine

@Observable
final class LocationService: NSObject {
    // MARK: - Published Properties
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var currentLocation: CLLocation?
    private(set) var currentSpeed: Double = 0 // mph
    private(set) var gpsAccuracy: GPSAccuracy?
    private(set) var locationInfo: LocationInfo?
    private(set) var isLocationServiceEnabled = false
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastGeocodingTime: Date?
    private var lastGeocodingLocation: CLLocation?
    private let geocodingInterval: TimeInterval = 5.0 // 5 seconds
    private let geocodingDistanceThreshold: CLLocationDistance = 50 // 50 meters
    
    // Speed smoothing
    private var speedHistory: [Double] = []
    private let maxSpeedHistorySize = 5
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .automotiveNavigation
        
        // Don't request background location for a speedometer app
        // locationManager.allowsBackgroundLocationUpdates = false
        
        updateAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Guide user to settings
            break
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus.isAuthorized else { return }
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        locationManager.startUpdatingLocation()
        isLocationServiceEnabled = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationServiceEnabled = false
    }
    
    func updateSpeedSmoothing(_ smoothingFactor: Double) {
        // Clear history when smoothing changes significantly
        if speedHistory.count > 2 {
            speedHistory.removeAll()
        }
    }
    
    // MARK: - Private Methods
    private func updateAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
    }
    
    private func processSpeedReading(_ location: CLLocation) {
        let rawSpeed = max(0, location.speed * 2.23694) // Convert m/s to mph
        
        // Handle invalid speeds
        guard location.speed >= 0 else {
            return // Invalid reading
        }
        
        // Add to history
        speedHistory.append(rawSpeed)
        if speedHistory.count > maxSpeedHistorySize {
            speedHistory.removeFirst()
        }
        
        // Apply smoothing
        let smoothedSpeed = calculateSmoothedSpeed()
        
        // Update current speed (very low speeds treated as stationary)
        currentSpeed = smoothedSpeed < 0.5 ? 0 : smoothedSpeed
    }
    
    private func calculateSmoothedSpeed() -> Double {
        guard !speedHistory.isEmpty else { return 0 }
        
        // Use weighted average with more weight on recent readings
        var weightedSum: Double = 0
        var totalWeight: Double = 0
        
        for (index, speed) in speedHistory.enumerated() {
            let weight = Double(index + 1) // More recent readings have higher weight
            weightedSum += speed * weight
            totalWeight += weight
        }
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0
    }
    
    private func updateGPSAccuracy(_ location: CLLocation) {
        gpsAccuracy = GPSAccuracy(
            horizontalAccuracy: location.horizontalAccuracy,
            speedAccuracy: location.speedAccuracy
        )
    }
    
    private func shouldUpdateLocationInfo(for location: CLLocation) -> Bool {
        // Throttle geocoding requests
        if let lastTime = lastGeocodingTime,
           Date().timeIntervalSince(lastTime) < geocodingInterval {
            return false
        }
        
        // Check distance threshold
        if let lastLocation = lastGeocodingLocation,
           location.distance(from: lastLocation) < geocodingDistanceThreshold {
            return false
        }
        
        // Only geocode if we have reasonable accuracy
        return location.horizontalAccuracy < 100
    }
    
    private func updateLocationInfo(for location: CLLocation) {
        lastGeocodingTime = Date()
        lastGeocodingLocation = location
        
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                
                await MainActor.run {
                    if let placemark = placemarks.first {
                        self.locationInfo = LocationInfo(
                            streetName: placemark.thoroughfare,
                            cityName: placemark.locality,
                            countryCode: placemark.isoCountryCode,
                            timestamp: Date()
                        )
                    }
                }
            } catch {
                // Handle geocoding error silently
                print("Geocoding failed: \(error)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus()
        
        if authorizationStatus.isAuthorized {
            startLocationUpdates()
        } else {
            stopLocationUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        updateGPSAccuracy(location)
        processSpeedReading(location)
        
        if shouldUpdateLocationInfo(for: location) {
            updateLocationInfo(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        // Handle location errors appropriately
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                stopLocationUpdates()
            case .locationUnknown:
                // Continue trying
                break
            default:
                break
            }
        }
    }
}

// MARK: - CLAuthorizationStatus Extension
extension CLAuthorizationStatus {
    var isAuthorized: Bool {
        return self == .authorizedWhenInUse || self == .authorizedAlways
    }
    
    var isDenied: Bool {
        return self == .denied || self == .restricted
    }
}