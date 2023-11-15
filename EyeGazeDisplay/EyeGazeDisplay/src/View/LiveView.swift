import SwiftUI

struct LiveView: View {
    @StateObject var viewModel = HeatMapViewModel() // ViewModel for LiveView

    var body: some View {
        VStack {

            // Using HeatMapView with the heatmap data from the viewModel
            if let heatMapData = viewModel.heatMap {
                HeatMapView(heatmapData: heatMapData)
            } else {
                Text("Loading heatmap data...")
            }
        }
    }
}
