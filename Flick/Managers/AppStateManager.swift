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
    
    init() {
        // Wake up the Managers immediately to ensure iPhone listens for commands even if the UI hasn't loaded yet.
        _ = WatchConnectivityManager.shared
        _ = iOSMediaManager.shared
        HapticManager.shared.prepare()
        
        let settings = SharedSettings.load()
        
        // Determine initial state
        if settings.isTutorialCompleted {
            self.currentState = .main
        } else if settings.hasCompletedInitialSetup {
            self.currentState = .waitingForWatch
        } else {
            self.currentState = .welcome
        }
        
        // Listen for tutorial completion from Watch
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let settings = SharedSettings.load()
            if settings.isTutorialCompleted {
                self?.currentState = .main
            }
        }
    }
    
    func completeWelcome() {
        currentState = .playbackChoice
    }
    
    func completePlaybackChoice(useShortcuts: Bool) {
        var settings = SharedSettings.load()
        settings.useShortcutsForPlayback = useShortcuts
        settings.hasCompletedInitialSetup = true
        SharedSettings.save(settings)
        
        currentState = .waitingForWatch
    }
    
    func goToMain() {
        currentState = .main
    }
}
