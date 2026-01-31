import SwiftUI

@main
struct VolumeSyncApp: App {
    @StateObject private var store = Store()
    
    var body: some Scene {
        MenuBarExtra("VolumeSync", systemImage: "speaker.wave.3.fill") {
            DeviceMenu(store: store)
        }
        .menuBarExtraStyle(.window) // Allows complex content like sliders
    }
}
