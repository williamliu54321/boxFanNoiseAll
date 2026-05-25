//
//  BoxFanNoiseApp.swift
//  BoxFanNoise
//
//  Created by William Liu on 2026-05-24.
//

import SwiftUI
import SuperwallKit

@main
struct BoxFanNoiseApp: App {
    @State private var showOnboarding = !OnboardingView.hasSeen
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Superwall.configure(apiKey: "pk_mw79OK0xopem1ra19AAKP")
        // Tell Superwall whether this user has finished onboarding. The session_start
        // campaign's audience filter (completedOnboarding == true) reads this.
        Superwall.shared.setUserAttributes([
            "completedOnboarding": OnboardingView.hasSeen
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        // Mark the attribute true the moment they finish so the
                        // next session can fire the session_start paywall.
                        Superwall.shared.setUserAttributes(["completedOnboarding": true])
                        showOnboarding = false
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active && OnboardingView.hasSeen {
                        // Audience filter on the dashboard gates this for non-onboarded users,
                        // but the extra guard keeps us safe from misconfig.
                        Superwall.shared.register(placement: "session_start")
                    }
                }
        }
    }
}
