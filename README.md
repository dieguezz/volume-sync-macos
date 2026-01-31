# VolumeSync 🎧

**VolumeSync** is a native macOS application designed to solve the volume control limitation of **Aggregate Devices**.

By default, when you combine multiple speakers in macOS (e.g., two Bluetooth speakers or a USB + Bluetooth setup), the system disables volume control. VolumeSync restores that control.

![VolumeSync Screenshot](./volumesync_screenshot.png)

## Features ✨

*   **⚡️ Virtual Master Control**: Increase and decrease volume for all devices in the group simultaneously using your standard **volume keys**.
*   **🎚️ Independent Control**: Adjust balance individually. For example, set the left speaker to 30% and the right one to 80%.
*   **🧠 Relative Adjustment**: When using volume keys, the app respects the volume offset between your devices (if one is lower than the other, both will rise but keep that ratio).
*   **🖥️ Native OSD**: Displays the classic macOS volume visual HUD on screen so you always know the current level.
*   **🍎 100% Native**: Written in Swift and SwiftUI, lightweight, and designed following Apple's Human Interface Guidelines.

## Installation & Usage 🚀

### Requirements
*   macOS 14 (Sonoma) or newer.
*   Xcode 15+ (if compiling from source).

### How to Run (from source)

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/volumesync.git
    cd volumesync
    ```

2.  **Build and Run**:
    ```bash
    swift run
    ```
    *Or open `Package.swift` in Xcode and hit Play.*

### Required Permissions 🔐
For the app to intercept volume keys (F11/F12 or dedicated media keys), you need to grant **Accessibility** permission:

1.  When opening the app for the first time, macOS should ask for permissions.
2.  If not, go to **System Settings** > **Privacy & Security** > **Accessibility**.
3.  Add your Terminal (if running via `swift run`) or the `VolumeSync` app to the list and enable it.

## User Guide

1.  Open **Audio MIDI Setup** on your Mac and create your Aggregate Device (or Multi-Output Device).
2.  Open **VolumeSync**. You will see a speaker icon in the menu bar.
3.  Click it and select your aggregate device from the list.
4.  Done! You can now use your keyboard volume keys.
5.  If you want to adjust each speaker separately, open the menu and use the individual sliders.

---
Made with Swift, SwiftUI, and CoreAudio.
