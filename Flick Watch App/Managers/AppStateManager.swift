//
//  AppStateManager.swift
//  Flick
//
//  Created by Liam Lefohn on 1/27/26.
//
// Tracks which screen to show

import SwiftUI
import Combine

enum AppState {
    case welcome
    case tutorial
    case main
}

class AppStateManager: ObservableObject {
    @Published var currentState: AppState
    @Published var isLeftWrist: Bool = true
    @Published var isTapEnabled: Bool
    @Published var isFlickDirectionReversed: Bool
    
    init() {
        let wristLocation = WKInterfaceDevice.current().wristLocation
        self.isLeftWrist = (wristLocation == .left)
        
        // Load from shared storage
        let settings = SharedSettings.load()
        self.isTapEnabled = settings.isTapEnabled
        self.isFlickDirectionReversed = settings.isFlickDirectionReversed
        
        let hasCompletedWelcome = UserDefaults.standard.bool(forKey: "hasCompletedWelcome")
        self.currentState = hasCompletedWelcome ? .main : .welcome
    }
    
    // Explicitly save when toggle changes
    func saveSettings() {
        var settings = SharedSettings.load()
        settings.isTapEnabled = self.isTapEnabled
        settings.isFlickDirectionReversed = self.isFlickDirectionReversed
        SharedSettings.save(settings)
        
        print("⌚️ Settings saved to SharedSettings")
    }
    
    // Explicitly load when view appears
    func loadSettings() {
        let settings = SharedSettings.load()
        self.isTapEnabled = settings.isTapEnabled
        self.isFlickDirectionReversed = settings.isFlickDirectionReversed
        
        print("⌚️ Settings loaded from SharedSettings")
    }
    
    func completeWelcome() {
        UserDefaults.standard.set(true, forKey: "hasCompletedWelcome")
        currentState = .tutorial
    }
    
    func completeTutorial() {
        var settings = SharedSettings.load()
        settings.isTutorialCompleted = true
        SharedSettings.save(settings)
        currentState = .main
    }
     
    func resetToTutorial() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedWelcome")
        currentState = .tutorial
    }
    
    func resetToWelcome() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedWelcome")
        currentState = .welcome
    }
    
    func goToMain() {
        currentState = .main
    }
}
