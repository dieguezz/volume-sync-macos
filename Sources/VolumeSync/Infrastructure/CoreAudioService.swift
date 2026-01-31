import Foundation
import CoreAudio
// Note: In a real app we might need AudioToolbox or specific headers,
// but CoreAudio framework is usually sufficient for property listeners.

enum CoreAudioError: Error {
    case deviceNotFound
    case operationFailed(OSStatus)
    case invalidProperty
}

/// Service responsible for all direct interactions with CoreAudio.
/// It translates low-level C APIs into friendly Swift types.
final class CoreAudioService {
    
    // MARK: - Public API
    
    /// Returns a list of all available output devices.
    func getOutputDevices() -> [AudioDevice] {
        guard let deviceIDs = getAllDeviceIDs() else { return [] }
        
        return deviceIDs.compactMap { id -> AudioDevice? in
            // Filter only devices that have output channels
            guard hasOutputChannels(deviceID: id) else { return nil }
            return createAudioDevice(from: id)
        }
    }
    
    /// Sets the volume for a specific device.
    func setVolume(_ volume: Volume, for deviceID: AudioObjectID) throws {
        // Master channel is 0, usually used for master volume.
        // Some devices only accept volume on channels 1 & 2.
        // We try master first, then individual channels if failed.
        
        let volumeValue = volume.value
        let propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain // Master
        )
        
        if canSetProperty(id: deviceID, address: propertyAddress) {
            try setProperty(id: deviceID, address: propertyAddress, value: volumeValue)
        } else {
            // Try setting on channels 1 and 2 (Stereo)
            // This is a simplification; a robust app would iterate all channels.
            let leftAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: 1
            )
            let rightAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: 2
            )
            
            if canSetProperty(id: deviceID, address: leftAddress) {
                try setProperty(id: deviceID, address: leftAddress, value: volumeValue)
            }
            if canSetProperty(id: deviceID, address: rightAddress) {
                try setProperty(id: deviceID, address: rightAddress, value: volumeValue)
            }
        }
    }
    
    // MARK: - Internal Helpers
    
    private func createAudioDevice(from id: AudioObjectID) -> AudioDevice {
        let name = getDeviceName(id: id)
        let volume = getVolume(id: id)
        let isMuted = getMuteState(id: id)
        let isAggregate = isAggregateDevice(id: id)
        let subDevices = isAggregate ? getSubDevices(id: id) : []
        
        return AudioDevice(
            id: id,
            name: name,
            volume: volume,
            isMuted: isMuted,
            isAggregate: isAggregate,
            subDevices: subDevices
        )
    }
    
    private func getAllDeviceIDs() -> [AudioObjectID]? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        return getPropertyDataArray(id: AudioObjectID(kAudioObjectSystemObject), address: address)
    }
    
    private func hasOutputChannels(deviceID: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        guard let buffers = getPropertyData(id: deviceID, address: address, type: AudioBufferList.self) else {
            return false
        }
        
        // Check if any buffer has channels
        // Note: Generic Swift handling of C-struct AudioBufferList is tricky because of the variable length array.
        // For simplicity, we just check if the size is > 0 and assume at least one stream exists.
        // A more rigorous check would iterate mNumberBuffers.
        return buffers.mNumberBuffers > 0
    }
    
    private func getDeviceName(id: AudioObjectID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        return getPropertyData(id: id, address: address, type: CFString.self) as String? ?? "Unknown Device"
    }
    
    private func getVolume(id: AudioObjectID) -> Volume {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if let val = getPropertyData(id: id, address: address, type: Float32.self) {
            return Volume(val)
        }
        
        // Try channel 1 if master fails
        address.mElement = 1
        if let val = getPropertyData(id: id, address: address, type: Float32.self) {
            return Volume(val)
        }
        
        return Volume(0.5) // Default fallback
    }
    
    private func getMuteState(id: AudioObjectID) -> Bool {
         var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        // Mute is Int32 (0 or 1)
        if let val = getPropertyData(id: id, address: address, type: UInt32.self) {
            return val == 1
        }
        return false
    }
    
    private func isAggregateDevice(id: AudioObjectID) -> Bool {
        // A simple check is to see if it supports the subdevice list property
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioAggregateDevicePropertyActiveSubDeviceList, // Or kAudioAggregateDevicePropertyComposition
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        return hasProperty(id: id, address: address)
    }
    
    private func getSubDevices(id: AudioObjectID) -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioAggregateDevicePropertyActiveSubDeviceList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        guard let subDeviceIDs: [AudioObjectID] = getPropertyDataArray(id: id, address: address) else {
            return []
        }
        
        return subDeviceIDs.map { createAudioDevice(from: $0) }
    }
    
    // MARK: - Core Audio Low Level Wrappers
    
    private func hasProperty(id: AudioObjectID, address: AudioObjectPropertyAddress) -> Bool {
        var addr = address
        return AudioObjectHasProperty(id, &addr)
    }
    
    private func canSetProperty(id: AudioObjectID, address: AudioObjectPropertyAddress) -> Bool {
        var addr = address
        var writable: DarwinBoolean = false
        let status = AudioObjectIsPropertySettable(id, &addr, &writable)
        return status == noErr && writable.boolValue
    }
    
    private func getPropertyData<T>(id: AudioObjectID, address: AudioObjectPropertyAddress, type: T.Type) -> T? {
        var addr = address
        var size = UInt32(MemoryLayout<T>.size)
        var data = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { data.deallocate() }
        
        let status = AudioObjectGetPropertyData(id, &addr, 0, nil, &size, data)
        guard status == noErr else { return nil }
        
        return data.pointee
    }
    
    private func getPropertyDataArray<T>(id: AudioObjectID, address: AudioObjectPropertyAddress) -> [T]? {
        var addr = address
        var size: UInt32 = 0
        
        // Get size first
        var status = AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size)
        guard status == noErr else { return nil }
        
        let count = Int(size) / MemoryLayout<T>.size
        var data = Array<T>(repeating: getZero(), count: count)
        
        status = AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &data)
        guard status == noErr else { return nil }
        
        return data
    }
    
    // Helper to get a zero-initialized value for array creation
    private func getZero<T>() -> T {
        let ptr = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { ptr.deallocate() }
        memset(ptr, 0, MemoryLayout<T>.size)
        return ptr.pointee
    }
    
    private func setProperty<T>(id: AudioObjectID, address: AudioObjectPropertyAddress, value: T) throws {
        var addr = address
        var val = value
        let size = UInt32(MemoryLayout<T>.size)
        
        let status = AudioObjectSetPropertyData(id, &addr, 0, nil, size, &val)
        if status != noErr {
            throw CoreAudioError.operationFailed(status)
        }
    }
}
