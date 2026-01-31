import Foundation
import CoreAudio

/// Represents an audio device in the system.
/// This is an immutable entity designed for Functional Programming usage.
struct AudioDevice: Identifiable, Equatable {
    /// The CoreAudio ObjectID for the device.
    let id: AudioObjectID
    
    /// The user-visible name of the device.
    let name: String
    
    /// The current volume of the device.
    let volume: Volume
    
    /// Whether the device is currently muted.
    let isMuted: Bool
    
    /// Whether this is an aggregate device (virtual device combining others).
    let isAggregate: Bool
    
    /// List of sub-devices if this is an aggregate device.
    /// Empty if not an aggregate device.
    let subDevices: [AudioDevice]
}
