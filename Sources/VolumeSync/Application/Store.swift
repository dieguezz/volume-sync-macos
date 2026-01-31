import Foundation
import Combine

/// Specific Store Implementation for Audio App.
/// Manages state and executes side-effects (interacting with CoreAudio).
final class Store: ObservableObject {
    @Published private(set) var state: AppState
    private let coreAudio: CoreAudioService
    private let mediaKeys: MediaKeyService
    
    init(initialState: AppState = AppState(), 
         coreAudio: CoreAudioService = CoreAudioService(),
         mediaKeys: MediaKeyService = MediaKeyService()) {
        self.state = initialState
        self.coreAudio = coreAudio
        self.mediaKeys = mediaKeys
        
        // Bind media key events
        self.mediaKeys.onEvent = { [weak self] action in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.dispatch(action)
                
                // Trigger OSD for volume keys
                if case .increaseVolume = action { self.showOSD() }
                if case .decreaseVolume = action { self.showOSD() }
                if case .toggleMute = action { self.showOSD() }
            }
        }
        
        // Start listening
        self.mediaKeys.start()
    }
    
    private func showOSD() {
        OSDManager.shared.show(volume: state.virtualVolume.value, isMuted: state.isMuted)
    }
    
    func dispatch(_ action: AudioAction) {
        // Update state
        state = audioReducer(state: state, action: action)
        
        // Handle Side Effects
        handleSideEffects(action: action)
    }
    
    private func handleSideEffects(action: AudioAction) {
        switch action {
        case .refreshDevices:
            let devices = coreAudio.getOutputDevices()
            dispatch(.devicesUpdated(devices))
            
        case .selectDevice:
            // Persist selection?
            break
            
        case .setVolume, .increaseVolume, .decreaseVolume, .toggleMute:
            applyVolumeToDevice()
            
        case .setSubDeviceVolume(let id, let val):
             try? coreAudio.setVolume(Volume(val), for: id)
            
        case .setError:
            // Log or show alert?
            break
            
        default:
            break
        }
    }
    
    private func applyVolumeToDevice() {
        guard let device = state.selectedDevice else { return }
        
        let targetVolume = state.isMuted ? Volume(0) : state.virtualVolume
        
        // If aggregate, apply to sub-devices based on our STATE, not just the master virtual volume.
        // If we just increased volume, the Reducer updated the SubDevices list in State.
        // We should apply THOSE values.
        if device.isAggregate {
            for sub in device.subDevices {
                // If muted, we send 0, otherwise we use the sub-device's calculated volume from state
                let vol = state.isMuted ? Volume(0) : sub.volume
                try? coreAudio.setVolume(vol, for: sub.id)
            }
        } else {
            try? coreAudio.setVolume(targetVolume, for: device.id)
        }
    }
}
