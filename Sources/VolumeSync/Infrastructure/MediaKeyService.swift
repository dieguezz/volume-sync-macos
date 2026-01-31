import Cocoa
import CoreGraphics

/// Service to intercept global media keys (Volume Up/Down/Mute).
/// Requires Accessibility Permissions.
class MediaKeyService {
    
    // Callback when a key is pressed.
    var onEvent: ((AudioAction) -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init() {}
    
    func start() {
        // We listen for NSSystemDefined events
        // kCGEventSystemDefined = 14
        let systemDefinedMask = (1 << 14)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(systemDefinedMask),
            callback: mediaKeyCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap. Check Accessibility Permissions.")
            onEvent?(.setError("Missing Accessibility Permissions"))
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        
        // Add to main run loop
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    // ... stop ...
}

// Helper Constants
private let NX_KEYTYPE_SOUND_UP: Int32 = 0
private let NX_KEYTYPE_SOUND_DOWN: Int32 = 1
private let NX_KEYTYPE_MUTE: Int32 = 7

// C-function callback for CGEventTap
func mediaKeyCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
    let service = Unmanaged<MediaKeyService>.fromOpaque(userInfo).takeUnretainedValue()
    
    // kCGEventSystemDefined = 14
    if type.rawValue == 14 {
        // ... (rest of logic)
        // NX_KEYTYPE_SOUND_UP = 0, NX_KEYTYPE_SOUND_DOWN = 1, NX_KEYTYPE_MUTE = 7
        // NSEvent provides a wrapper but inside CGEvent callback we deal with raw data usually.
        // However, we can convert CGEvent to NSEvent for easier inspection if we wanted, 
        // but let's stick to raw fields for performance and simplicity in Swift if possible,
        // or just use NSEvent(cgEvent:).
        
        if let nsEvent = NSEvent(cgEvent: event) {
            if nsEvent.type == .systemDefined && nsEvent.subtype.rawValue == 8 { // 8 is usually media keys
                let data1 = nsEvent.data1
                let keyCode = (data1 & 0xFFFF0000) >> 16
                let keyFlags = (data1 & 0x0000FFFF)
                let keyDown = ((keyFlags & 0xFF00) >> 8) == 0xA
                
                if keyDown {
                    switch Int32(keyCode) {
                    case NX_KEYTYPE_SOUND_UP:
                        service.onEvent?(.increaseVolume)
                        return nil // Consume event
                        
                    case NX_KEYTYPE_SOUND_DOWN:
                        service.onEvent?(.decreaseVolume)
                        return nil // Consume event
                        
                    case NX_KEYTYPE_MUTE:
                        service.onEvent?(.toggleMute)
                        return nil // Consume event
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    return Unmanaged.passUnretained(event)
}
