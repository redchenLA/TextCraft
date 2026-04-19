// TextCraft - AI Text Beautifier & Card Generator
// Created for App Store submission
// Target: iOS 16.0+

import SwiftUI

@main
struct TextCraftApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SubscriptionManager())
                .environmentObject(CardStore())
        }
    }
}
