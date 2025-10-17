//
//  UserSettings.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import SwiftUI

@Observable
class UserSettings {
    @AppStorage("speed_unit") var speedUnit: SpeedUnit = .metric
    @AppStorage("show_street_name") var showStreetName = true
    @AppStorage("show_trip_stats") var showTripStats = true
    @AppStorage("enable_haptics") var enableHaptics = true
    @AppStorage("enable_sound_alerts") var enableSoundAlerts = true
    @AppStorage("speed_smoothing") var speedSmoothing: Double = 0.3
    @AppStorage("color_theme") var colorTheme: ColorTheme = .dynamic
    @AppStorage("manual_speed_limit") var manualSpeedLimit: Int = 0
    @AppStorage("speed_limit_alerts") var speedLimitAlerts = true
}

enum SpeedUnit: String, CaseIterable {
    case metric = "kmh"
    case imperial = "mph"
    
    var displayName: String {
        switch self {
        case .metric: return "km/h"
        case .imperial: return "mph"
        }
    }
    
    var shortName: String {
        switch self {
        case .metric: return "km/h"
        case .imperial: return "mph"
        }
    }
    
    func convert(speedInMph: Double) -> Double {
        switch self {
        case .metric: return speedInMph * 1.60934
        case .imperial: return speedInMph
        }
    }
    
    func convertDistance(milesOrKm: Double) -> Double {
        switch self {
        case .metric: return milesOrKm * 1.60934
        case .imperial: return milesOrKm
        }
    }
    
    var distanceUnit: String {
        switch self {
        case .metric: return "km"
        case .imperial: return "mi"
        }
    }
}

enum ColorTheme: String, CaseIterable {
    case dynamic = "dynamic"
    case white = "white"
    case blue = "blue"
    case green = "green"
    
    var displayName: String {
        switch self {
        case .dynamic: return "Dynamic"
        case .white: return "White"
        case .blue: return "Blue"
        case .green: return "Green"
        }
    }
    
    func color(for speed: Double, speedLimit: Int?, isExceeding: Bool) -> Color {
        switch self {
        case .dynamic:
            if isExceeding {
                return .red
            } else if speed > 0 {
                return .green
            } else {
                return .gray
            }
        case .white: return .white
        case .blue: return .blue
        case .green: return .green
        }
    }
}