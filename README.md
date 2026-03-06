# SmartFlow 💧

> Smart Water Usage Monitoring System with ESP32 Integration

SmartFlow is a comprehensive iOS + watchOS water usage monitoring app that pairs with an ESP32 flow sensor to provide real-time water tracking, gamified conservation goals, and intelligent notifications. The app discovers your sensor automatically via network scanning, connects through BLE for first-time WiFi provisioning, and delivers live flow data over HTTP — all without touching a single config file on the microcontroller.

## Features ✨

### 🏠 Real-Time Monitoring
- Live water flow rate and total volume from ESP32 sensor
- Customizable daily/weekly/monthly limits with progress ring
- Multi-unit support (Liters / Gallons)
- Smart threshold notifications (configurable %) and limit-exceeded alerts

### 🔌 ESP32 Hardware Integration
- **Auto-Discovery** — scans your local network (mDNS + IP sweep) to find the sensor
- **BLE WiFi Provisioning** — set up freshly flashed ESP32 boards via Bluetooth, no serial monitor needed
- **Manual IP Fallback** — direct connection when auto-discovery isn't available
- **Live Data Polling** — continuous HTTP polling with auto-reconnect
- **On-Device Log Console** — terminal-style view for debugging ESP32 communication

### 🏆 Gamification
- **Achievements** — 10+ unlockable milestones across multiple categories
- **Streaks** — daily conservation streak tracking with freeze power-ups
- **Levels & XP** — earn experience for water-saving behavior
- **Droplet Currency** — collect and spend on in-app rewards
- **Daily Challenges** — fresh conservation goals each day
- **Shop** — spend droplets on power-ups and customizations

### ⌚ Apple Watch
- Companion watch app with usage ring, 7-day history chart, and quick actions
- WatchConnectivity sync (live messages + application context fallback)
- Set limits and reset usage directly from your wrist

### 🌍 Localization
- Full English and Spanish support
- Language selection during onboarding
- Centralized `LocalizationManager` for easy extension

### 🔔 Notifications
- Threshold alerts (default 80%) and limit-exceeded warnings
- Intelligent throttling to prevent notification spam
- Test notification feature with countdown

### 💰 Monetization
- Google AdMob banner integration (adaptive banner, ATT-compliant)
- Privacy manifest included (`PrivacyInfo.xcprivacy`)

## Requirements 📋

### iOS App
- iOS 16.0+
- Xcode 16.0+
- Swift 5.9+
- Google Mobile Ads SDK 13.1+ (via SPM)

### Hardware
- ESP32 Development Board
- YF-S201 Water Flow Sensor (or compatible hall-effect sensor)
- WiFi network (2.4 GHz)
- 5V power supply

## Installation 🚀

### 1. Clone
```bash
git clone https://github.com/r0bledas/SmartFlow.git
cd SmartFlow
```

### 2. Open & Build
```bash
open SmartFlow.xcodeproj
```
- Select your development team in Signing & Capabilities
- The Google Mobile Ads SDK is pulled automatically via Swift Package Manager
- Build and run on a real device (⌘+R)

### 3. ESP32 Setup
1. Flash `SmartFlow/ESP32WaterFlowINOfile/ESP32WaterFlow/ESP32WaterFlow.ino` to your ESP32
2. Connect the flow sensor signal wire to **GPIO 27**
3. Power on — the LED will blink, indicating provisioning mode
4. Open SmartFlow → Settings → **Setup New Device**
5. The app finds the ESP32 via BLE, sends your WiFi credentials, and connects automatically

## Project Structure 📁

```
SmartFlow/
├── SmartFlow/                          # iOS app target
│   ├── SmartFlowApp.swift              # App entry point, SDK init, ATT prompt
│   ├── ContentView.swift               # Tab navigation + onboarding
│   ├── Views/
│   │   ├── HomeView.swift              # Dashboard with progress ring + ad banner
│   │   ├── SetLimitView.swift          # Limit presets, slider, period selector
│   │   ├── HistoryView.swift           # Charts, stats, data export
│   │   ├── AchievementsView.swift      # Gamification UI + celebration overlay
│   │   ├── SettingsView.swift          # Connection, preferences, developer tools
│   │   ├── DeviceSetupView.swift       # BLE provisioning wizard (4-step flow)
│   │   ├── ConnectDeviceView.swift     # Manual IP / auto-discovery connection
│   │   ├── ShopView.swift              # Droplet currency shop
│   │   ├── LogView.swift               # ESP32 debug console
│   │   ├── OnboardingView.swift        # Language selection + first-run setup
│   │   └── AdBannerView.swift          # Google AdMob adaptive banner
│   ├── Models/
│   │   ├── WaterUsageModel.swift       # Core model: usage, limits, ESP32 HTTP
│   │   ├── WaterUsageModel+ESP32.swift # BLE data integration extension
│   │   ├── WaterUsageModel+Gamification.swift
│   │   ├── GamificationModel.swift     # Achievements, streaks, levels, challenges
│   │   ├── BluetoothManager.swift      # CoreBluetooth scanning + data transfer
│   │   └── WiFiProvisioningManager.swift # BLE-based WiFi setup for ESP32
│   ├── Connectivity/
│   │   └── WatchConnectivityManager.swift
│   ├── Utils/
│   │   ├── LocalizationManager.swift   # L() helper + EN/ES string tables
│   │   └── HapticFeedback.swift        # Taptic engine wrappers
│   ├── Info.plist                      # BLE, network, ATT, AdMob config
│   └── PrivacyInfo.xcprivacy          # Apple privacy manifest
├── SmartFlowWatchApp Watch App/        # watchOS target
│   ├── ContentView.swift               # Usage ring, history, quick actions
│   └── SmartFlowWatchInterface.swift   # WatchWaterUsageModel + WCSession
├── Shared/
│   └── WatchConnectivityManager.swift  # Shared connectivity helpers
└── ESP32WaterFlowINOfile/
    └── ESP32WaterFlow.ino              # Arduino firmware (BLE + HTTP + flow)
```

## Architecture 🏗️

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| State | `@EnvironmentObject` + `ObservableObject` |
| Persistence | `UserDefaults` (JSON-encoded history) |
| ESP32 Comms | HTTP polling (`URLSession`) + BLE provisioning (`CoreBluetooth`) |
| Watch Sync | `WatchConnectivity` (messages + app context + shared `UserDefaults`) |
| Ads | Google Mobile Ads SDK 13.1 (SPM) |
| Firmware | Arduino (ESP32), `WebServer.h`, `BLEDevice.h`, `ArduinoJson.h` |

## URL Scheme 🔗

```
smartflow://reset       # Reset water usage counter
```

## Contributing 🤝

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap 🗺️

- [ ] Cloud data backup and sync
- [ ] Multi-sensor support
- [ ] Leak detection algorithms
- [ ] HomeKit / Home Assistant integration
- [ ] Water quality monitoring
- [ ] Widget extensions

## License 📄

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for water conservation**

*SmartFlow — Making every drop count*
