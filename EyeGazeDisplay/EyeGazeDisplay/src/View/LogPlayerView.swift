import SwiftUI
import Combine

struct LogPlayerView: View {
    @StateObject var viewModel = LogPlayerViewModel()
    @State private var selectedLogIndex: Int? = 0
    @State private var currentHeatMapIndex = 0
    @State private var isPlaying = false // Play/Pause state
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationSplitView {
            // Display the log list
            if let logList = viewModel.logList {
                List(selection: $selectedLogIndex) {
                    ForEach(logList.indices, id: \.self) { index in
                        Text(logList[index]).tag(index)
                    }
                }
            } else {
                Text("Loading log list...")
            }
        } detail: {
            // Display the selected log detail
            if let index = selectedLogIndex, let logList = viewModel.logList, let heatMaps = viewModel.log, !heatMaps.isEmpty {
                VStack {
                    // Display HeatMapView
                    HeatMapView(heatmapData: heatMaps[currentHeatMapIndex], isVisibilityList: viewModel.isVisilityList?[currentHeatMapIndex])
                        .onReceive(timer) { _ in
                            if isPlaying {
                                currentHeatMapIndex = (currentHeatMapIndex + 1) % heatMaps.count
                            }
                        }
                    HStack{
                        Text("Selected Log: \(logList[index])")
                        
                        // Slider to manually control the heatmap frame
                        Slider(value: $currentHeatMapIndex.doubleValue, in: 0...Double(heatMaps.count - 1), step: 1)
                            .padding()
                            .onChange(of: currentHeatMapIndex) { newIndex, _ in
                                isPlaying = true // Stop playing when manually controlling the slider
                            }
                        
                        // Player Controls
                        playerControls
                    }
                }
            } else {
                Text("Please select a log")
            }
        }
        .onAppear {
            viewModel.getLogList()
        }
        .onChange(of: selectedLogIndex) { newIndex, _ in
            // newIndexがnilの場合、0をデフォルト値として使用
            if let logTitle = viewModel.logList?[selectedLogIndex ?? -1] {
                print(logTitle)
                viewModel.getSpecificLog(with: logTitle)
                isPlaying = true // Stop playing when a new log is selected
            }
        }
    }

    // Player controls view
    private var playerControls: some View {
        HStack {
            Button(action: {
                isPlaying = false
                currentHeatMapIndex = max(currentHeatMapIndex - 1, 0)
            }) {
                Image(systemName: "backward.fill")
            }
            .padding()

            Button(action: {
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            .padding()

            Button(action: {
                isPlaying = false
                currentHeatMapIndex = min(currentHeatMapIndex + 1, viewModel.log?.count ?? 0)
            }) {
                Image(systemName: "forward.fill")
            }
            .padding()
        }
    }
}

// Helper extension to bind Int with Slider
private extension Binding where Value == Int {
    var doubleValue: Binding<Double> {
        Binding<Double>(
            get: { Double(self.wrappedValue) },
            set: { self.wrappedValue = Int($0) }
        )
    }
}
