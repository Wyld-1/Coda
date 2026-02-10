//
//  SettingsView.swift (Watch)
//  Flick
//
//  Created by Liam Lefohn on 1/30/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var showCredits = false
    
    var body: some View {
        List {
            Section {
                // Reverse flick directions
                Toggle(isOn: Binding(
                    get: { appState.isFlickDirectionReversed },
                    set: { newValue in
                        appState.isFlickDirectionReversed = newValue
                        appState.saveSettings() // ← Save on change
                        WKInterfaceDevice.current().play(.click)
                    }
                )) {
                    HStack(spacing: 4) {
                        Text("Flip")
                        Image(systemName: "backward.fill")
                        Text("/")
                        Image(systemName: "forward.fill")
                    }
                }
                .tint(.orange)
                
                // Enable/disable tap for play/pause toggle
                Toggle(isOn: Binding(
                    get: { appState.isTapEnabled },
                    set: { newValue in
                        appState.isTapEnabled = newValue
                        appState.saveSettings() // Save on change
                        WKInterfaceDevice.current().play(.click)
                    }
                )) {
                    HStack(spacing: 4) {
                        Text("Tap screen to")
                        Image(systemName: "playpause.fill")
                    }
                }
                .tint(.orange)
                
                // Restart tutorial button
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    appState.resetToTutorial()
                }) {
                    ZStack {
                        Text("Replay tutorial")
                            .foregroundStyle(.orange)
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Credits button
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    showCredits = true
                }) {
                    ZStack {
                        Text("About")
                            .foregroundStyle(.secondary)
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .listStyle(.plain)
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
        .onAppear {
            appState.loadSettings() // ← Load when menu opens
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStateManager())
}
