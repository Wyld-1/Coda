//
//  WatchConnectivityManager.swift
//  Coda
//
//  Manages communication between Watch and iPhone
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Send Command (Watch → iPhone)
    func sendMediaCommand(_ command: MediaCommand) {
        guard WCSession.default.activationState == .activated else {
            print("❌ WCSession not activated")
            return
        }
        
        guard WCSession.default.isReachable else {
            print("❌ iPhone not reachable")
            return
        }
        
        let message = ["command": command.rawValue]
        
        WCSession.default.sendMessage(message, replyHandler: { reply in
            print("✅ Command sent: \(command.rawValue)")
        }, errorHandler: { error in
            print("❌ Error sending command: \(error.localizedDescription)")
        })
    }
    
    func syncSettings(_ settings: AppSettings) {
        guard WCSession.default.activationState == .activated else { return }
        
        do {
            let data = try JSONEncoder().encode(settings)
            let dict = ["settings": data]
            
            try WCSession.default.updateApplicationContext(dict)
            print("✅ Settings synced")
        } catch {
            print("❌ Error syncing settings: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📱 WCSession activated: \(activationState.rawValue)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📱 Reachability changed: \(session.isReachable)")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let data = applicationContext["settings"] as? Data,
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            // Save received settings
            SharedSettings.save(settings)
            print("✅ Settings received and saved")
        }
    }
    
    // MARK: - Receive Messages (iPhone side)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        #if os(iOS)
        print("📱 iPhone received message: \(message)")
        
        if let commandString = message["command"] as? String,
           let command = MediaCommand(rawValue: commandString) {
            DispatchQueue.main.async {
                iOSMediaManager.shared.handleCommand(command)
            }
        }
        #endif
    }
    
    // iOS-only delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 Session deactivated, reactivating...")
        session.activate()
    }
    #endif
}
