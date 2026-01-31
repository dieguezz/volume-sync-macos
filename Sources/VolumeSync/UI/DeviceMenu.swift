import SwiftUI

struct DeviceMenu: View {
    @ObservedObject var store: Store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Header
            HStack {
                Text("Volume Sync")
                    .font(.headline)
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
            
            // Device List
            Text("Select Output Device:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(store.state.availableDevices) { device in
                        DeviceRow(device: device, isSelected: device.id == store.state.selectedDevice?.id) {
                            store.dispatch(.selectDevice(device.id))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 200)
            
            Divider()
            
            // Active Device Control
            if let selected = store.state.selectedDevice {
                VStack(alignment: .leading) {
                    Text(selected.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Master Virtual Volume
                    HStack {
                        Image(systemName: store.state.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        Slider(value: Binding(
                            get: { store.state.virtualVolume.value },
                            set: { store.dispatch(.setVolume($0)) }
                        ), in: 0...1)
                    }
                    
                    // If Aggregate, show sub-devices?
                    // "Independent control for each device" requested.
                    if selected.isAggregate && !selected.subDevices.isEmpty {
                        Text("Sub-Devices")
                            .font(.caption)
                            .padding(.top, 4)
                        
                ForEach(selected.subDevices) { sub in
                    SubDeviceRow(name: sub.name, volume: sub.volume.value) { newVal in
                        store.dispatch(.setSubDeviceVolume(sub.id, newVal))
                    }
                }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .frame(width: 300)
        .onAppear {
            store.dispatch(.refreshDevices)
        }
    }
}

struct DeviceRow: View {
    let device: AudioDevice
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                Text(device.name)
                    .lineLimit(1)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct SubDeviceRow: View {
    let name: String
    let volume: Float
    let onChange: (Float) -> Void
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption2)
                .frame(width: 80, alignment: .leading)
                .lineLimit(1)
            
            Slider(value: Binding(
                get: { volume },
                set: { onChange($0) }
            ), in: 0...1)
        }
    }
}
