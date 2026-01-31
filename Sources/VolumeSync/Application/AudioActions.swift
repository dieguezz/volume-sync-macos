import Foundation
import CoreAudio

/// Enumeration of all possible actions that can change the state.
enum AudioAction {
    case refreshDevices
    case devicesUpdated([AudioDevice])
    case selectDevice(AudioObjectID)
    case setVolume(Float)
    case setSubDeviceVolume(AudioObjectID, Float)
    case increaseVolume
    case decreaseVolume
    case toggleMute
    case setError(String?)
}
