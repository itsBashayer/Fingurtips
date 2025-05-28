//
//  Untitled.swift
//  AnamelDemo
//
//  Created by Joury on 28/11/1446 AH.
//

import SwiftUI

struct AppRootView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some View {
        Group {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
    }
}

