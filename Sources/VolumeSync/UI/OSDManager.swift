import SwiftUI
import AppKit

// MARK: - OSD View
struct OSDView: View {
    let volume: Float
    let isMuted: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isMuted || volume == 0 ? "speaker.slash.fill" : "speaker.wave.3.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.secondary)
            
            ProgressView(value: isMuted ? 0 : volume)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 120)
                .tint(.secondary)
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

// MARK: - OSD Window Manager
class OSDManager: ObservableObject {
    static let shared = OSDManager()
    
    private var window: NSWindow?
    private var fadeTimer: Timer?
    
    private init() {
        setupWindow()
    }
    
    private func setupWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.center()
        
        // Position at bottom center (simulating macOS native HUD)
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 100
            let y = screenRect.minY + 140
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.window = window
    }
    
    func show(volume: Float, isMuted: Bool) {
        guard let window = window else { return }
        
        // Update content
        let contentView = OSDView(volume: volume, isMuted: isMuted)
        window.contentView = NSHostingView(rootView: contentView)
        
        // Show window
        window.alphaValue = 1.0
        window.orderFront(nil)
        
        // Reset timer
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.fadeOut()
        }
    }
    
    private func fadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            self.window?.animator().alphaValue = 0.0
        } completionHandler: {
           // self.window?.orderOut(nil)
        }
    }
}
