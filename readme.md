// TextCraft - AI Text Beautifier & Card Generator
// Target: iOS 16.0+
// License: All rights reserved

# TextCraft

Transform your words into beautiful shareable cards.

## Features
- 10 card templates (3 free, 7 premium)
- Customizable font size
- Share directly to social media
- No watermark with premium subscription

## Setup
1. Open `TextCraft.xcodeproj` in Xcode
2. Set your development team in Signing & Capabilities
3. Configure StoreKit subscription products in App Store Connect:
   - `com.textcraft.premium.weekly` - ¥6/week
   - `com.textcraft.premium.monthly` - ¥18/month
   - `com.textcraft.premium.yearly` - ¥128/year
4. Build and run

## CI/CD
GitHub Actions workflow automatically builds the IPA on push to `main` branch.
See `.github/workflows/build.yml` for details.

## Architecture
- **ContentView.swift** - Main UI with text input, template picker, preview
- **CardView.swift** - Card rendering with templates and decorative elements
- **SubscriptionManager.swift** - StoreKit 2 subscription handling
- **CardStore.swift** - Simple card history management

## Requirements
- Xcode 15+
- iOS 16.0+
- Swift 5.9+
