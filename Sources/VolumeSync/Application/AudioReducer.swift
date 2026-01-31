import Foundation

/// Pure function that creates a new AppState from the old state and an action.
func audioReducer(state: AppState, action: AudioAction) -> AppState {
    var newState = state
    
    switch action {
    case .refreshDevices:
        // verifying handled by effect / store
        break
        
    case .devicesUpdated(let devices):
        newState.availableDevices = devices
        
        // If we have a selected device, update it with fresh data
        if let selected = state.selectedDevice {
            if let updated = devices.first(where: { $0.id == selected.id }) {
                newState.selectedDevice = updated
            } else {
                // Device incorrect/disconnected, deselect?
                // For now, keep it or nil it.
                // newState.selectedDevice = nil
            }
        }
        
    case .selectDevice(let id):
        if let device = state.availableDevices.first(where: { $0.id == id }) {
            newState.selectedDevice = device
            // Reset virtual volume to match device ?
            // Since aggregate devices might not have volume, we default to 0.5 or keep current.
            // But if it has volume, we use it.
            newState.virtualVolume = device.volume
            newState.isMuted = device.isMuted
        }
        
    case .setVolume(let val):
        let oldVal = state.virtualVolume.value
        let newVal = Volume(val).value
        let delta = newVal - oldVal
        
        newState.virtualVolume = Volume(newVal)
        
        if newState.virtualVolume.value == 0 {
            newState.isMuted = true
        } else {
            newState.isMuted = false
        }
        
        // Update sub-devices relatively
        if let selected = newState.selectedDevice, selected.isAggregate {
            let updatedSubs = selected.subDevices.map { sub -> AudioDevice in
                return AudioDevice(
                    id: sub.id,
                    name: sub.name,
                    volume: Volume(sub.volume.value + delta),
                    isMuted: sub.isMuted,
                    isAggregate: sub.isAggregate,
                    subDevices: sub.subDevices
                )
            }
            newState.selectedDevice = AudioDevice(
                id: selected.id,
                name: selected.name,
                volume: selected.volume,
                isMuted: selected.isMuted,
                isAggregate: selected.isAggregate,
                subDevices: updatedSubs
            )
        }
        
    case .setSubDeviceVolume(let id, let val):
        // Find the sub-device and update it in our local state model
        if let selected = state.selectedDevice {
             if selected.isAggregate {
                let updatedSubs = selected.subDevices.map { sub -> AudioDevice in
                    if sub.id == id {
                        return AudioDevice(id: sub.id, name: sub.name, volume: Volume(val), isMuted: sub.isMuted, isAggregate: sub.isAggregate, subDevices: sub.subDevices)
                    }
                    return sub
                }
                newState.selectedDevice = AudioDevice(id: selected.id, name: selected.name, volume: selected.volume, isMuted: selected.isMuted, isAggregate: selected.isAggregate, subDevices: updatedSubs)
            }
        }
        
    case .increaseVolume:
        let step: Float = 1.0/16.0
        newState.virtualVolume = Volume(state.virtualVolume.value + step)
        newState.isMuted = false
        
        // Also update sub-devices in state so UI reflects the change immediately
        if let selected = newState.selectedDevice, selected.isAggregate {
            let updatedSubs = selected.subDevices.map { sub -> AudioDevice in
                return AudioDevice(id: sub.id, name: sub.name, volume: Volume(sub.volume.value + step), isMuted: sub.isMuted, isAggregate: sub.isAggregate, subDevices: sub.subDevices)
            }
            newState.selectedDevice = AudioDevice(id: selected.id, name: selected.name, volume: selected.volume, isMuted: selected.isMuted, isAggregate: selected.isAggregate, subDevices: updatedSubs)
        }
        
    case .decreaseVolume:
        let step: Float = 1.0/16.0
        newState.virtualVolume = Volume(state.virtualVolume.value - step)
        
        // Also update sub-devices in state
        if let selected = newState.selectedDevice, selected.isAggregate {
            let updatedSubs = selected.subDevices.map { sub -> AudioDevice in
                return AudioDevice(id: sub.id, name: sub.name, volume: Volume(sub.volume.value - step), isMuted: sub.isMuted, isAggregate: sub.isAggregate, subDevices: sub.subDevices)
            }
            newState.selectedDevice = AudioDevice(id: selected.id, name: selected.name, volume: selected.volume, isMuted: selected.isMuted, isAggregate: selected.isAggregate, subDevices: updatedSubs)
        }
        
    case .toggleMute:
        newState.isMuted.toggle()
        
    case .setError(let error):
        newState.errorMessage = error
    }
    
    return newState
}
