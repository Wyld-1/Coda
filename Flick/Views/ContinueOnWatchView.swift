//
//  ContinueOnWatchView.swift
//  Flick
//
//  Wait for Watch tutorial
//

import SwiftUI

struct ContinueOnWatchView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [.orange.opacity(0.15), .clear]),
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    // Ripples
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 6)
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 2.3 : 1.3)
                            .opacity(isAnimating ? 0 : 0.3)
                            .animation(
                                .easeOut(duration: 2.3)
                                .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    
                    // Central icon
                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.3))
                            .frame(width: 140, height: 140)
                            .shadow(color: .orange.opacity(0.2), radius: 20)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(systemName: "applewatch")
                            .font(.system(size: 70))
                            .foregroundStyle(.orange)
                    }
                }
                .frame(height: 350)
                
                // Text instructions
                VStack(spacing: 20) {
                    Text("Continue on Apple Watch")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                    
                    Text("Complete the tutorial to finish setup.")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // MARK: - Debug buttons (Only visible in Debug Mode)
                #if DEBUG
                Button(action: {
                    // 1. Force save the setting so it persists
                    var settings = SharedSettings.load()
                    settings.isTutorialCompleted = true
                    SharedSettings.save(settings)
                    
                    withAnimation {
                        appState.currentState = .welcome
                    }
                }) {
                    Text("DEBUG: RESTART")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.bottom, 20)
                
                Button(action: {
                    // 1. Force save the setting so it persists
                    var settings = SharedSettings.load()
                    settings.isTutorialCompleted = true
                    SharedSettings.save(settings)
                    
                    // 2. Tell AppState to move on
                    appState.goToMain()
                }) {
                    Text("DEBUG: SKIP TO MAIN")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.bottom, 20)
                #endif
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ContinueOnWatchView()
        .environmentObject(AppStateManager())
}
