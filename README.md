# SmartFlow 💧

> Smart Water Usage Monitoring System with ESP32 Integration

SmartFlow is a comprehensive iOS water usage monitoring application that integrates with ESP32 hardware to provide real-time water flow tracking and intelligent usage management. The app features automatic ESP32 device discovery via network scanning, manual IP connection fallback, customizable daily water limits with smart notifications, historical usage analytics, and Apple Watch synchronization.

## Features ✨

### 🏠 Core Functionality
- **Real-time Water Monitoring**: Live tracking of water flow rates and total usage
- **Smart Usage Limits**: Set and monitor daily water consumption goals
- **Historical Analytics**: Detailed charts and usage history tracking
- **Multi-unit Support**: Switch between Liters and Gallons
- **Apple Watch Integration**: Sync data and monitor from your wrist

### 🔌 ESP32 Hardware Integration
- **Automatic Device Discovery**: Network scanning to find ESP32 sensors automatically
- **Manual IP Connection**: Fallback option for problematic networks
- **Real-time Data Polling**: Continuous monitoring with background task management
- **Connection Status Monitoring**: Visual feedback and animated connection states
- **Bluetooth Support**: BLE fallback communication

### 🔔 Smart Notifications
- **Threshold Alerts**: Customizable warnings (default 80% of daily limit)
- **Limit Exceeded Notifications**: Alerts when daily usage is exceeded
- **Intelligent Throttling**: Prevents notification spam with smart timing
- **Test Notifications**: 3-second countdown test feature for verification

### ⚙️ Advanced Settings
- **Developer Mode**: Logging view for ESP32 communication debugging
- **Data Export**: Export usage data for analysis
- **Connection Management**: Sophisticated network discovery and manual configuration
- **Notification Customization**: Adjustable alert thresholds and preferences

## Screenshots 📱

| Home Screen | Settings | History |
|-------------|----------|---------|
| Real-time usage monitoring | Device connection & preferences | Usage analytics & trends |

## Requirements 📋

### iOS App
- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+
- iPhone/iPad compatible
- Apple Watch (optional)

### Hardware
- ESP32 Development Board
- Water Flow Sensor (compatible with ESP32)
- WiFi Network
- Power Supply for ESP32

## Installation 🚀

### 1. Clone the Repository
```bash
git clone https://github.com/r0bledas/SmartFlow.git
cd SmartFlow
```

### 2. Open in Xcode
```bash
open SmartFlow.xcodeproj
```

### 3. Configure Signing & Capabilities
- Select your development team
- Update bundle identifier if needed
- Enable necessary capabilities (Background Processing, Push Notifications)

### 4. Build and Run
- Select your target device
- Build and run the project (⌘+R)

## Hardware Setup 🔧

### ESP32 Configuration
1. Flash the included Arduino sketch: `ESP32_SmartFlow_BLE.ino`
2. Connect your water flow sensor to the designated GPIO pins
3. Configure WiFi credentials in the Arduino code
4. Power on the ESP32 and verify LED indicators

### Network Setup
- Ensure ESP32 and iOS device are on the same WiFi network
- Note the ESP32's IP address for manual connection if needed
- Configure any necessary firewall rules for communication

Detailed hardware setup instructions are available in `ESP32_Hardware_Setup.md`.

## Usage 📖

### Getting Started
1. **Launch the App**: SmartFlow will automatically search for ESP32 devices
2. **Connect Device**: Use automatic discovery or manual IP entry
3. **Set Limits**: Configure your daily water usage goals
4. **Monitor Usage**: View real-time data on the Home screen

### Key Features

#### Home Screen
- Current usage display with progress indicators
- Real-time flow rate monitoring
- Quick access to limit adjustments
- Connection status indicators

#### Settings
- **Flow Sensor**: Connect/disconnect ESP32 devices
- **Device Information**: View connection details and statistics  
- **Daily Limits**: Set and modify usage goals
- **Notifications**: Configure alert thresholds and test notifications
- **Apple Watch**: Enable synchronization

#### History
- Daily, weekly, and monthly usage trends
- Historical data visualization
- Usage pattern analysis

### Troubleshooting Connection Issues
1. **Automatic Discovery Failed**: 
   - Try manual IP connection
   - Verify both devices are on same network
   - Check ESP32 power and WiFi connection

2. **Data Not Updating**:
   - Check ESP32 sensor connections
   - Verify water flow sensor functionality
   - Enable developer logs for debugging

## API & Integration 🔗

### URL Scheme Support
SmartFlow supports URL schemes for external integration:
```
smartflow://reset        # Reset water usage counter
smartflow://connect      # Trigger ESP32 connection
smartflow://settings     # Open settings screen
```

### Apple Watch Integration
- Automatic data synchronization
- Independent watch interface
- Real-time usage monitoring from wrist

## Development 💻

### Project Structure
```
SmartFlow/
├── SmartFlow/              # Main iOS app
│   ├── Views/              # SwiftUI views
│   ├── Models/             # Data models and ESP32 integration
│   ├── Connectivity/       # Watch and network communication
│   └── Utilities/          # Helper functions and extensions
├── SmartFlow Watch App/    # Apple Watch companion
├── ESP32_SmartFlow_BLE.ino # Arduino code for ESP32
└── README.md              # This file
```

### Key Components
- **WaterUsageModel**: Core data management and ESP32 communication
- **SettingsView**: Device connection and configuration interface
- **HomeView**: Main dashboard and usage display
- **BluetoothManager**: BLE communication fallback
- **WatchConnectivityManager**: Apple Watch synchronization

### Building from Source
1. Ensure all dependencies are available
2. Configure signing certificates
3. Update hardware configuration as needed
4. Build for your target devices

## Contributing 🤝

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Areas for Contribution
- Additional sensor support
- Enhanced analytics features
- UI/UX improvements
- Documentation updates
- Bug fixes and optimizations

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support 💬

- **Issues**: Report bugs and request features via GitHub Issues
- **Documentation**: Check the wiki for detailed guides
- **Community**: Join discussions in GitHub Discussions

## Roadmap 🗺️

### Upcoming Features
- [ ] Cloud data backup and sync
- [ ] Multi-device support
- [ ] Advanced analytics and insights
- [ ] Integration with smart home systems
- [ ] Water quality monitoring
- [ ] Leak detection algorithms

### Version History
- **v1.0.0** (September 2025): Initial release with ESP32 integration
- **v0.9.0**: Beta release with Apple Watch support
- **v0.8.0**: Alpha release with basic monitoring

## Acknowledgments 🙏

- ESP32 community for hardware support and documentation
- Apple for SwiftUI and WatchOS frameworks
- Open source community for inspiration and libraries
- Water conservation organizations for raising awareness

---

**Built with ❤️ for water conservation**

*SmartFlow - Making every drop count*
