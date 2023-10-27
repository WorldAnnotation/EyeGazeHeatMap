//
//  EyeGazeDisplayApp.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import SwiftUI

// グラデーションを生成する関数
func generateHeatmapData(rows: Int, columns: Int, maxValue: Double) -> [[Double]] {
    let centerX = Double(columns - 1) / 2.0
    let centerY = Double(rows - 1) / 2.0
    let maxDistance = hypot(centerX, centerY)

    var heatmap = [[Double]](repeating: [Double](repeating: 0.0, count: columns), count: rows)

    for y in 0..<rows {
        for x in 0..<columns {
            let distance = hypot(Double(x) - centerX, Double(y) - centerY)
            let value = maxValue * (1.0 - (distance / maxDistance))
            heatmap[y][x] = min(maxValue, max(0, value))
        }
    }
    return heatmap
}

// 生成プログラムを使用して新しいデータを取得
let newData = generateHeatmapData(rows: 30, columns: 21, maxValue: 100.0)
let sampleData = HeatmapData(rows: 30, columns: 21, data: newData)
let viewModel = HeatMapViewModel(heatmap: sampleData)

@main
struct EyeGazeDisplayApp: App {
    var body: some Scene {
        WindowGroup {
            HeatMapView(viewModel: viewModel)
        }
    }
}
