//
//  HeatMapViewModel.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import Foundation
import SwiftUI

class HeatMapViewModel: ObservableObject {
    @Published var heatmap: HeatmapData
    
    init(heatmap:HeatmapData) {
        self.heatmap = heatmap
    }
    
    func colorForValue(_ value: Double) -> Color {
        let normalizedValue = value / 100.0 //正規化
        return Color(red: normalizedValue, green: 0, blue: 1.0 - normalizedValue)
    }
}
