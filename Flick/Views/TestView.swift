//
//  TestView.swift
//  Flick
//
//  Created by Liam Lefohn on 2/6/26.
//

import SwiftUI
import MediaPlayer

struct TestView: View {
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private let mediaManager = iOSMediaManager.shared
    
    @State private var isPlaying = false
    @State private var settings = SharedSettings.load()
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Mode indicator
                HStack(spacing: 8) {
                    Image(systemName: modeIcon)
                        .font(.caption)
                    Text("\(modeLabel) Mode")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 20)
                
                // Controls
                HStack(spacing: 60) {
                    Button(action: {
                        mediaManager.handleCommand(.previousTrack)
                        HapticManager.shared.playImpact()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 40))
                    }
                    
                    Button(action: {
                        mediaManager.handleCommand(.playPause)
                        HapticManager.shared.playImpact()
                        // Manual state toggle for non-Shortcuts modes
                        if settings.playbackMethod != .shortcuts {
                            isPlaying.toggle()
                        }
                    }) {
                        Image(systemName: playPauseIcon)
                            .font(.system(size: 55))
                            .frame(width: 80, height: 80)
                    }
                    
                    Button(action: {
                        mediaManager.handleCommand(.nextTrack)
                        HapticManager.shared.playImpact()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 40))
                    }
                }
                .foregroundStyle(.primary)
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .presentationDetents([.fraction(0.25)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(35)
        .onAppear {
            settings = SharedSettings.load()
            updatePlaybackState()
        }
        // Note: onChange of enum requires Equatable check or just raw value
        .onChange(of: settings.playbackMethod.rawValue) { _, _ in
            settings = SharedSettings.load()
            updatePlaybackState()
        }
    }
    
    // MARK: - Logic
    
    private var modeIcon: String {
        switch settings.playbackMethod {
        case .appleMusic: return "music.note"
        case .spotify: return "waveform"
        case .shortcuts: return "bolt.fill"
        }
    }
    
    private var modeLabel: String {
        switch settings.playbackMethod {
        case .appleMusic: return "Apple Music"
        case .spotify: return "Spotify"
        case .shortcuts: return "Shortcuts"
        }
    }
    
    private var playPauseIcon: String {
        switch settings.playbackMethod {
        case .appleMusic:
            return isPlaying ? "pause.fill" : "play.fill"
        case .spotify:
            // Spotify state is hard to read synchronously here, defaulting to generic
            return "playpause.fill"
        case .shortcuts:
            return "playpause.fill"
        }
    }
    
    private func updatePlaybackState() {
        if settings.playbackMethod == .appleMusic {
            isPlaying = musicPlayer.playbackState == .playing
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        Text("Background App Content")
            .foregroundStyle(.gray)
    }
    .sheet(isPresented: .constant(true)) {
        TestView()
    }
}
