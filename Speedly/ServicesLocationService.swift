//
//  LocationService.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import Foundation
import CoreLocation
import MapKit
import Combine

final class LocationService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var currentSpeed: Double = 0 // mph
    @Published private(set) var gpsAccuracy: GPSAccuracy?
    @Published private(set) var locationInfo: LocationInfo?
    @Published private(set) var isLocationServiceEnabled = false
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
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
        print("Requesting location permission. Current status: \(authorizationStatus)")
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // User needs to go to settings - this should be handled by the UI
            print("Location permission denied/restricted")
            break
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
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
            await performModernGeocoding(for: location)
        }
    }
    
    @MainActor
    private func performModernGeocoding(for location: CLLocation) async {
        do {
            // Use MKLocalSearch for modern geocoding (no deprecation warnings)
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = ""
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 200,
                longitudinalMeters: 200
            )
            
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            if let mapItem = response.mapItems.first {
                self.locationInfo = LocationInfo(
                    streetName: mapItem.placemark.thoroughfare,
                    cityName: mapItem.placemark.locality,
                    countryCode: mapItem.placemark.countryCode,
                    timestamp: Date()
                )
                return
            }
        } catch {
            print("MKLocalSearch failed: \(error.localizedDescription)")
        }
        
        // If MKLocalSearch fails, set basic location info without street details
        self.locationInfo = LocationInfo(
            streetName: nil,
            cityName: "Unknown Location",
            countryCode: nil,
            timestamp: Date()
        )
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization changed to: \(manager.authorizationStatus)")
        updateAuthorizationStatus()
        
        if authorizationStatus.isAuthorized {
            print("Location authorized, starting updates")
            startLocationUpdates()
        } else {
            print("Location not authorized, stopping updates")
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
