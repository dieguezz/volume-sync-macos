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
        newState.virtualVolume = Volume(val)
        // Mute logic: if 0, true?
        if newState.virtualVolume.value == 0 {
            newState.isMuted = true
        } else {
            newState.isMuted = false
        }
        
    case .increaseVolume:
        let step: Float = 1.0/16.0 // Standard macOS step
        newState.virtualVolume = Volume(state.virtualVolume.value + step)
        newState.isMuted = false
        
    case .decreaseVolume:
        let step: Float = 1.0/16.0
        newState.virtualVolume = Volume(state.virtualVolume.value - step)
        
    case .toggleMute:
        newState.isMuted.toggle()
        
    case .setError(let error):
        newState.errorMessage = error
    }
    
    return newState
}
