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
    
    init(heatmap: HeatmapData) {
        self.heatmap = heatmap
    }
    
    func colorForValue(_ value: Double) -> Color {
        let normalizedValue = value / 100.0 //正規化
        let red = 0.25 + (0.75 * normalizedValue) // 0.25から1.0の範囲で赤を増加させる
        let green = 0.2 * (1.0 - normalizedValue) // 0.2から0.0の範囲で緑を減少させる
        return Color(red: red, green: green, blue: 0.0, opacity: normalizedValue)
    }
}
