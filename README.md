# Pomodoro Timer iOS

A multiplatform (iOS/macOS) Pomodoro timer app built with SwiftUI that integrates with your goals CSV file and tracks time spent on specific tasks.

## Features

- **iOS App**: Full-screen interface with Live Activities support for Dynamic Island and Lock Screen
- **macOS App**: Menu bar timer with popover interface (maintaining original functionality)
- **CSV Integration**: Read goals from CSV files and log completed Pomodoros
- **Background Execution**: Timer continues in the background on both platforms
- **Notifications**: Receive notifications when your Pomodoro completes

## Requirements

- iOS 16.1+ (for Live Activities)
- macOS 12.0+
- Xcode 16.3+

## Getting Started

1. Clone this repository
2. Open the project in Xcode
3. Build and run on your preferred platform

## Implementation Details

The app is structured as a SwiftUI multiplatform project with:

- Shared core functionality between platforms
- Platform-specific UI designs
- Live Activities support for iOS
- Menu bar integration for macOS

## License

This project is available under the MIT license.