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
                self?.dispatch(action)
            }
        }
        
        // Start listening
        self.mediaKeys.start()
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
        
        // If aggregate, apply to sub-devices
        if device.isAggregate {
            for sub in device.subDevices {
                try? coreAudio.setVolume(targetVolume, for: sub.id)
            }
        } else {
            try? coreAudio.setVolume(targetVolume, for: device.id)
        }
        
        // Also update the UI representation of the device by refreshing?
        // Or blindly assume it worked?
        // Ideally we refresh devices to read back actual values, but that might be slow.
    }
}
