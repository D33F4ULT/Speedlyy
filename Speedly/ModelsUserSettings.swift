//
//  UserSettings.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import SwiftUI
import Combine

final class UserSettings: ObservableObject {
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Manual Published Properties to avoid conflicts
    
    private var _speedUnit: SpeedUnit = .metric {
        didSet {
            objectWillChange.send()
            userDefaults.set(_speedUnit.rawValue, forKey: "speed_unit")
        }
    }
    
    var speedUnit: SpeedUnit {
        get { _speedUnit }
        set { _speedUnit = newValue }
    }
    
    private var _showStreetName: Bool = true {
        didSet {
            objectWillChange.send()
            userDefaults.set(_showStreetName, forKey: "show_street_name")
        }
    }
    
    var showStreetName: Bool {
        get { _showStreetName }
        set { _showStreetName = newValue }
    }
    
    private var _showTripStats: Bool = true {
        didSet {
            objectWillChange.send()
            userDefaults.set(_showTripStats, forKey: "show_trip_stats")
        }
    }
    
    var showTripStats: Bool {
        get { _showTripStats }
        set { _showTripStats = newValue }
    }
    
    private var _enableHaptics: Bool = true {
        didSet {
            objectWillChange.send()
            userDefaults.set(_enableHaptics, forKey: "enable_haptics")
        }
    }
    
    var enableHaptics: Bool {
        get { _enableHaptics }
        set { _enableHaptics = newValue }
    }
    
    private var _enableSoundAlerts: Bool = true {
        didSet {
            objectWillChange.send()
            userDefaults.set(_enableSoundAlerts, forKey: "enable_sound_alerts")
        }
    }
    
    var enableSoundAlerts: Bool {
        get { _enableSoundAlerts }
        set { _enableSoundAlerts = newValue }
    }
    
    private var _speedSmoothing: Double = 0.3 {
        didSet {
            objectWillChange.send()
            userDefaults.set(_speedSmoothing, forKey: "speed_smoothing")
        }
    }
    
    var speedSmoothing: Double {
        get { _speedSmoothing }
        set { _speedSmoothing = newValue }
    }
    
    private var _colorTheme: ColorTheme = .dynamic {
        didSet {
            objectWillChange.send()
            userDefaults.set(_colorTheme.rawValue, forKey: "color_theme")
        }
    }
    
    var colorTheme: ColorTheme {
        get { _colorTheme }
        set { _colorTheme = newValue }
    }
    
    private var _manualSpeedLimit: Int = 0 {
        didSet {
            objectWillChange.send()
            userDefaults.set(_manualSpeedLimit, forKey: "manual_speed_limit")
        }
    }
    
    var manualSpeedLimit: Int {
        get { _manualSpeedLimit }
        set { _manualSpeedLimit = newValue }
    }
    
    private var _speedLimitAlerts: Bool = true {
        didSet {
            objectWillChange.send()
            userDefaults.set(_speedLimitAlerts, forKey: "speed_limit_alerts")
        }
    }
    
    var speedLimitAlerts: Bool {
        get { _speedLimitAlerts }
        set { _speedLimitAlerts = newValue }
    }
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load speed unit
        if let rawValue = userDefaults.string(forKey: "speed_unit"),
           let unit = SpeedUnit(rawValue: rawValue) {
            _speedUnit = unit
        }
        
        // Load boolean settings
        if userDefaults.object(forKey: "show_street_name") != nil {
            _showStreetName = userDefaults.bool(forKey: "show_street_name")
        }
        
        if userDefaults.object(forKey: "show_trip_stats") != nil {
            _showTripStats = userDefaults.bool(forKey: "show_trip_stats")
        }
        
        if userDefaults.object(forKey: "enable_haptics") != nil {
            _enableHaptics = userDefaults.bool(forKey: "enable_haptics")
        }
        
        if userDefaults.object(forKey: "enable_sound_alerts") != nil {
            _enableSoundAlerts = userDefaults.bool(forKey: "enable_sound_alerts")
        }
        
        if userDefaults.object(forKey: "speed_limit_alerts") != nil {
            _speedLimitAlerts = userDefaults.bool(forKey: "speed_limit_alerts")
        }
        
        // Load double setting
        if userDefaults.object(forKey: "speed_smoothing") != nil {
            _speedSmoothing = userDefaults.double(forKey: "speed_smoothing")
        }
        
        // Load color theme
        if let rawValue = userDefaults.string(forKey: "color_theme"),
           let theme = ColorTheme(rawValue: rawValue) {
            _colorTheme = theme
        }
        
        // Load integer setting
        if userDefaults.object(forKey: "manual_speed_limit") != nil {
            _manualSpeedLimit = userDefaults.integer(forKey: "manual_speed_limit")
        }
    }
}

enum SpeedUnit: String, CaseIterable, Codable {
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

enum ColorTheme: String, CaseIterable, Codable {
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