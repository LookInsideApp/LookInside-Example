import SwiftUI

/// The standard watchOS controls in one list, to compare how each is built.
struct ControlsView: View {
    @State private var isShuffleOn = false
    @State private var repeatMode = RepeatMode.off
    @State private var volume = 6.0
    @State private var sleepTimerMinutes = 15
    @State private var message = ""

    var body: some View {
        List {
            Section("Playback") {
                Toggle("Shuffle", isOn: $isShuffleOn)
                Picker("Repeat", selection: $repeatMode) {
                    ForEach(RepeatMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                VStack(alignment: .leading) {
                    Text("Volume")
                    Slider(value: $volume, in: 0 ... 10, step: 1)
                }
                Stepper("Sleep in \(sleepTimerMinutes) min", value: $sleepTimerMinutes, in: 5 ... 60, step: 5)
            }
            Section("Status") {
                HStack {
                    Gauge(value: volume, in: 0 ... 10) {
                        Text("Vol")
                    }
                    .gaugeStyle(.accessoryCircular)
                    ProgressView()
                }
            }
            Section("Reply") {
                TextField("Message", text: $message)
                Button("Send") {
                    message = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(message.isEmpty)
            }
        }
        .navigationTitle("Controls")
    }
}
