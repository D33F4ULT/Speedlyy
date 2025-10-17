//
//  SpeedData.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - Speed Data Models

struct SpeedReading {
    let speed: Double // m/s
    let accuracy: Double
    let timestamp: Date
    let location: CLLocation
    
    var speedInMph: Double { speed * 2.23694 }
    var speedInKmh: Double { speed * 3.6 }
}

struct GPSAccuracy {
    let horizontalAccuracy: Double
    let speedAccuracy: Double
    
    var qualityLevel: QualityLevel {
        switch horizontalAccuracy {
        case ...5: return .excellent
        case ...15: return .good
        case ...50: return .fair
        case ...100: return .poor
        default: return .unavailable
        }
    }
    
    var description: String {
        switch qualityLevel {
        case .excellent: return "Excellent (\(Int(horizontalAccuracy))m)"
        case .good: return "Good (\(Int(horizontalAccuracy))m)"
        case .fair: return "Fair (\(Int(horizontalAccuracy))m)"
        case .poor: return "Poor (\(Int(horizontalAccuracy))m)"
        case .unavailable: return "No Signal"
        case .normal: return "Normal (\(Int(horizontalAccuracy))m)"
        }
    }
}

enum QualityLevel {
    case excellent, good, fair, poor, unavailable, normal
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .unavailable: return .gray
        case .normal: return .blue
        }
    }
}

// MARK: - Trip Data

class TripData: ObservableObject {
    @Published private(set) var startTime: Date?
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var distance: Double = 0 // miles
    @Published private(set) var maxSpeed: Double = 0 // mph
    @Published private(set) var speedSamples: [Double] = []
    
    var averageSpeed: Double {
        guard !speedSamples.isEmpty else { return 0 }
        return speedSamples.reduce(0, +) / Double(speedSamples.count)
    }
    
    var isActive: Bool { startTime != nil }
    
    func start() {
        guard startTime == nil else { return }
        startTime = Date()
        reset()
    }
    
    func stop() {
        startTime = nil
    }
    
    func reset() {
        duration = 0
        distance = 0
        maxSpeed = 0
        speedSamples.removeAll()
    }
    
    func addSpeedSample(_ speed: Double) {
        speedSamples.append(speed)
        maxSpeed = max(maxSpeed, speed)
        
        // Keep only recent samples for performance
        if speedSamples.count > 1000 {
            speedSamples.removeFirst(100)
        }
    }
    
    func addDistance(_ additionalDistance: Double) {
        distance += additionalDistance
    }
    
    func updateDuration() {
        guard let startTime = startTime else { return }
        duration = Date().timeIntervalSince(startTime)
    }
}

// MARK: - Speed Limit Data

struct SpeedLimitInfo {
    let limit: Int // Always stored in the detected unit
    let source: SpeedLimitSource
    let confidence: Float // 0.0 - 1.0
    let detectedAt: Date
}

enum SpeedLimitSource: Equatable {
    case openStreetMap
    case appleRoadData
    case userSet
    case estimated(reason: String)
    
    var displayName: String {
        switch self {
        case .openStreetMap: return "OpenStreetMap"
        case .appleRoadData: return "Apple Maps"
        case .userSet: return "Manual"
        case .estimated(let reason): return "Estimated (\(reason))"
        }
    }
}

// MARK: - Location Info

struct LocationInfo {
    let streetName: String?
    let cityName: String?
    let countryCode: String?
    let timestamp: Date
    
    var displayAddress: String {
        var components: [String] = []
        
        if let street = streetName, !street.isEmpty {
            components.append(street)
        }
        
        if let city = cityName, !city.isEmpty {
            components.append(city)
        }
        
        return components.joined(separator: ", ")
    }
}

import SwiftUI