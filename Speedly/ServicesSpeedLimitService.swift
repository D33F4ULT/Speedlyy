//
//  SpeedLimitService.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import Foundation
import CoreLocation
import Combine

final class SpeedLimitService: ObservableObject {
    @Published private(set) var currentSpeedLimit: SpeedLimitInfo?
    
    private let session = URLSession.shared
    private var lastQueryTime: Date?
    private var lastQueryLocation: CLLocation?
    private let queryInterval: TimeInterval = 10.0 // 10 seconds
    private let queryDistanceThreshold: CLLocationDistance = 100 // 100 meters
    
    // MARK: - Public Methods
    
    func updateSpeedLimit(for location: CLLocation) async {
        guard shouldQuerySpeedLimit(for: location) else { return }
        
        lastQueryTime = Date()
        lastQueryLocation = location
        
        // Try OpenStreetMap first, then fallback to estimation
        if let osmLimit = await queryOpenStreetMapSpeedLimit(location: location) {
            await MainActor.run {
                self.currentSpeedLimit = osmLimit
            }
        } else if let estimated = estimateSpeedLimit(for: location) {
            await MainActor.run {
                self.currentSpeedLimit = estimated
            }
        }
    }
    
    func setManualSpeedLimit(_ limit: Int) {
        let manualLimit = SpeedLimitInfo(
            limit: limit,
            source: .userSet,
            confidence: 1.0,
            detectedAt: Date()
        )
        
        currentSpeedLimit = manualLimit
    }
    
    func clearManualSpeedLimit() {
        // Only clear if it was manually set
        if currentSpeedLimit?.source == .userSet {
            currentSpeedLimit = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldQuerySpeedLimit(for location: CLLocation) -> Bool {
        // Throttle requests
        if let lastTime = lastQueryTime,
           Date().timeIntervalSince(lastTime) < queryInterval {
            return false
        }
        
        // Check distance threshold
        if let lastLocation = lastQueryLocation,
           location.distance(from: lastLocation) < queryDistanceThreshold {
            return false
        }
        
        // Only query with good accuracy
        return location.horizontalAccuracy < 50
    }
    
    private func queryOpenStreetMapSpeedLimit(location: CLLocation) async -> SpeedLimitInfo? {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        let overpassQuery = """
        [out:json][timeout:5];
        (
          way(around:50,\(lat),\(lon))["highway"]["maxspeed"];
        );
        out tags 1;
        """
        
        guard let encodedQuery = overpassQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(encodedQuery)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        request.setValue("Speedly/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await session.data(for: request)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let elements = json["elements"] as? [[String: Any]],
                  let firstElement = elements.first,
                  let tags = firstElement["tags"] as? [String: Any],
                  let maxspeedString = tags["maxspeed"] as? String else {
                return nil
            }
            
            // Parse speed limit from various formats
            let speedLimit = parseSpeedLimitString(maxspeedString)
            
            if let limit = speedLimit {
                return SpeedLimitInfo(
                    limit: limit,
                    source: .openStreetMap,
                    confidence: 0.9,
                    detectedAt: Date()
                )
            }
            
        } catch {
            print("OpenStreetMap query failed: \(error)")
        }
        
        return nil
    }
    
    private func parseSpeedLimitString(_ speedString: String) -> Int? {
        // Handle various formats: "50", "50 mph", "50 km/h", etc.
        let cleanString = speedString
            .replacingOccurrences(of: " mph", with: "")
            .replacingOccurrences(of: " km/h", with: "")
            .replacingOccurrences(of: "mph", with: "")
            .replacingOccurrences(of: "kmh", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        return Int(cleanString)
    }
    
    private func estimateSpeedLimit(for location: CLLocation) -> SpeedLimitInfo? {
        // This is a very basic estimation - in a real app you might want more sophisticated logic
        // based on road type, area type, etc.
        
        let estimatedLimit: Int
        let reason: String
        
        // Default to a reasonable speed limit
        // In practice, you might use additional data sources or ML models
        estimatedLimit = 50 // Default urban speed limit
        reason = "Urban default"
        
        return SpeedLimitInfo(
            limit: estimatedLimit,
            source: .estimated(reason: reason),
            confidence: 0.3,
            detectedAt: Date()
        )
    }
}

// MARK: - Helper Extensions
extension SpeedLimitInfo {
    func convertedLimit(for unit: SpeedUnit) -> Int {
        switch unit {
        case .metric:
            return limit // Assuming limit is in km/h
        case .imperial:
            return Int(Double(limit) / 1.60934) // Convert km/h to mph
        }
    }
}