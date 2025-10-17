//
//  SpeedLimitEditorView.swift
//  Speedly
//
//  Created by Dušan Lukášek on 18.10.2025.
//

import SwiftUI

struct SpeedLimitEditorView: View {
    @EnvironmentObject private var model: SpeedometerModel
    @Environment(\.dismiss) private var dismiss
    @State private var speedLimitText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: "speedometer")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    
                    // Title and Description
                    VStack(spacing: 12) {
                        Text("Set Speed Limit")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        
                        Text("Enter the speed limit for this area")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Speed Input
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            TextField("50", text: $speedLimitText)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 120, height: 80)
                                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                                .focused($isTextFieldFocused)
                            
                            Text(model.settings.speedUnit.shortName)
                                .font(.title2.bold())
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        // Preset Buttons
                        PresetSpeedLimitsView(speedLimitText: $speedLimitText)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Set Limit Button
                        Button {
                            setSpeedLimit()
                        } label: {
                            Text("Set Speed Limit")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    isValidInput ? Color.blue : Color.gray,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                        }
                        .disabled(!isValidInput)
                        .animation(.easeInOut(duration: 0.2), value: isValidInput)
                        
                        // Clear Manual Limit Button (if exists)
                        if model.settings.manualSpeedLimit > 0 {
                            Button {
                                clearManualLimit()
                            } label: {
                                Text("Clear Manual Limit")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isTextFieldFocused = false
                        }
                    }
                }
            }
            .onAppear {
                setupInitialValue()
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidInput: Bool {
        guard let limit = Int(speedLimitText) else { return false }
        return limit > 0 && limit <= 200 // Reasonable speed limit range
    }
    
    // MARK: - Actions
    
    private func setupInitialValue() {
        if model.settings.manualSpeedLimit > 0 {
            speedLimitText = "\(model.settings.manualSpeedLimit)"
        }
    }
    
    private func setSpeedLimit() {
        guard let limit = Int(speedLimitText), limit > 0 else { return }
        
        model.setManualSpeedLimit(limit)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
    
    private func clearManualLimit() {
        model.clearManualSpeedLimit()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Preset Speed Limits

struct PresetSpeedLimitsView: View {
    @EnvironmentObject private var model: SpeedometerModel
    @Binding var speedLimitText: String
    
    private var presetLimits: [Int] {
        switch model.settings.speedUnit {
        case .imperial:
            return [25, 35, 45, 55, 65, 75]
        case .metric:
            return [30, 50, 70, 90, 110, 130]
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Common Limits")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(presetLimits, id: \.self) { limit in
                    Button {
                        speedLimitText = "\(limit)"
                        hapticFeedback()
                    } label: {
                        Text("\(limit)")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(speedLimitText == "\(limit)" ? .black : .white.opacity(0.8))
                            .frame(width: 60, height: 40)
                            .background(
                                speedLimitText == "\(limit)" ? .white : .white.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .animation(.easeInOut(duration: 0.15), value: speedLimitText)
                }
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    SpeedLimitEditorView()
        .environmentObject(SpeedometerModel())
}