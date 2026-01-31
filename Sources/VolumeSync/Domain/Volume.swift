import Foundation

/// Represents a volume level between 0.0 and 1.0.
/// - Note: Values outside this range are clamped.
struct Volume: Equatable {
    let value: Float
    
    static let min: Float = 0.0
    static let max: Float = 1.0
    
    init(_ value: Float) {
        self.value = Swift.min(Swift.max(value, Volume.min), Volume.max)
    }
    
    var isMuted: Bool {
        return value == 0.0
    }
}
