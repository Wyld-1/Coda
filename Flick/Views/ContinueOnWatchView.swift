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
                            .scaleEffect(isAnimating ? 2.3 : 1.2)
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
                
                /*
                // Status pill
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.orange)
                        .controlSize(.regular)
                    
                    Text("Waiting for completion...")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(0.5)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.bottom, 60)
                 */
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
