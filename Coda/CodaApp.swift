//
//  CodaApp.swift
//  Coda
//
//  iOS companion app
//

import SwiftUI

@main
struct CodaApp: App {
    init() {
        // Initialize Watch Connectivity
        _ = WatchConnectivityManager.shared
        print("📱 iOS app initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
