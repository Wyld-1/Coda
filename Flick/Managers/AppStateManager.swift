//
//  AppStateManager.swift
//  Flick iOS
//
//  Manages app state and view routing
//

import Foundation
import Combine
import UIKit

enum AppState {
    case welcome
    case playbackChoice
    case waitingForWatch
    case main
}

class AppStateManager: ObservableObject {
    @Published var currentState: AppState
    
    private var isIOSSetupFinished: Bool {
        get { UserDefaults.standard.bool(forKey: "iOS_Setup_Finished") }
        set { UserDefaults.standard.set(newValue, forKey: "iOS_Setup_Finished") }
    }
    
    init() {
        // 1. Initialize Managers
        _ = WatchConnectivityManager.shared
        _ = iOSMediaManager.shared
        HapticManager.shared.prepare()
        
        // 2. Load Data
        let settings = SharedSettings.load()
        
        let localSetupFinished = UserDefaults.standard.bool(forKey: "iOS_Setup_Finished")
        
        // 3. Determine Initial State (using the local constant)
        if settings.isTutorialCompleted && localSetupFinished {
            self.currentState = .main
        } else if localSetupFinished {
            self.currentState = .waitingForWatch
        } else {
            self.currentState = .welcome
        }
        
        // 4. Listen for Watch updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let freshSettings = SharedSettings.load()
            
            // Now we can use 'self.isIOSSetupFinished' safely
            if freshSettings.isTutorialCompleted && self.isIOSSetupFinished {
                self.currentState = .main
            }
        }
    }
    
    func completeWelcome() {
        currentState = .playbackChoice
    }
    
    func completePlaybackChoice(useShortcuts: Bool) {
        // 1. Save preferences to Shared Settings (synced)
        var settings = SharedSettings.load()
        settings.useShortcutsForPlayback = useShortcuts
        SharedSettings.save(settings)
        
        // 2. Save Setup State to LOCAL storage
        isIOSSetupFinished = true
        
        // 3. Check Watch status
        if settings.isTutorialCompleted {
            currentState = .main
        } else {
            currentState = .waitingForWatch
        }
    }
    
    func goToMain() {
        currentState = .main
    }
    
    // MARK: - Debug Helper
    func resetForDebug() {
        // Reset Local State
        isIOSSetupFinished = false
        
        // Reset Shared State
        var settings = SharedSettings.load()
        settings.isTutorialCompleted = false
        SharedSettings.save(settings)
        
        currentState = .welcome
    }
}
