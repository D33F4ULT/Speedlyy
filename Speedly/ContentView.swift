//
//  ContentView.swift
//  Speedly
//
//  Created by Dušan Lukášek on 17.10.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = SpeedometerModel()
    @State private var showSettings = false
    @State private var showTripSummary = false
    @State private var showSpeedLimitEditor = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Main Content
                Group {
                    if model.isLocationAuthorized {
                        SpeedometerView()
                            .environmentObject(model)
                    } else {
                        LocationPermissionView()
                            .environmentObject(model)
                    }
                }
                
                // Settings Button Overlay
                if model.isLocationAuthorized {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(model)
        }
        .sheet(isPresented: $showTripSummary) {
            TripSummaryView()
                .environmentObject(model)
        }
        .sheet(isPresented: $showSpeedLimitEditor) {
            SpeedLimitEditorView()
                .environmentObject(model)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // Handle orientation changes if needed
        }
        .onTapGesture(count: 2) {
            if model.currentTrip.isActive && model.currentTrip.duration > 0 {
                showTripSummary = true
            }
        }
    }
}

#Preview {
    ContentView()
}
