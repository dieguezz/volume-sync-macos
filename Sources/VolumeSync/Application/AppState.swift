import Foundation

/// The global immutable state of the application.
struct AppState: Equatable {
    /// List of all available output devices found in the system.
    var availableDevices: [AudioDevice] = []
    
    /// The currently selected device (intended to be the Aggregate Device).
    var selectedDevice: AudioDevice?
    
    /// The virtual master volume for the selected device.
    var virtualVolume: Volume = Volume(0.5)
    
    /// Whether the virtual master is muted.
    var isMuted: Bool = false
    
    /// Error message to display, if any.
    var errorMessage: String?
}
