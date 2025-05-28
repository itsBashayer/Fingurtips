//
//  ANAMILApp.swift
//  ANAMIL
//
//  Created by BASHAER AZIZ on 29/10/1446 AH.
//

import SwiftUI

@main
struct ANAMILApp: App {

    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var voiceRecorderManager = VoiceRecorderManager() // Create instance of VoiceRecorderManager
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(voiceRecorderManager)
                .environmentObject(cloudKitManager)
        }
    }
}
