//
//  LocationPermissionConfiguration.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

/*
 IMPORTANT: Location Permission Setup
 
 To fix the location permission issue, you need to add the following keys to your Info.plist file:
 
 1. Right-click on your Info.plist file in Xcode
 2. Select "Open As" > "Source Code"
 3. Add these keys inside the <dict> section:
 
 <key>NSLocationWhenInUseUsageDescription</key>
 <string>Speedly needs access to your location to display accurate speed data. All location data stays on your device and is never shared.</string>
 
 <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
 <string>Speedly needs access to your location to display accurate speed data. All location data stays on your device and is never shared.</string>
 
 OR if you prefer the Property List format:
 - Add a new row in Info.plist
 - Key: "Privacy - Location When In Use Usage Description"
 - Type: String
 - Value: "Speedly needs access to your location to display accurate speed data. All location data stays on your device and is never shared."
 
 Alternative method using Xcode's interface:
 1. Select your project in the navigator
 2. Select your target
 3. Go to the "Info" tab
 4. Add "Privacy - Location When In Use Usage Description" with the description above
 
 Without these entries, iOS will not show the permission dialog and the button will appear to do nothing.
 */

import Foundation

// This file is for documentation purposes only
// The actual location permission configuration needs to be done in Info.plist