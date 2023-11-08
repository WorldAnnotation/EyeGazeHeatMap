//
//  EyeGazeDisplayApp.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import SwiftUI
import Foundation

// グラデーションを生成

func generateHeatmapData(rows: Int, columns: Int, maxValue: Double) -> [[Double]] {
    let centerX1 = Double(columns) / 3.0
    let centerY1 = Double(rows) / 3.0
    
    let centerX2 = 2.0 * Double(columns) / 3.0
    let centerY2 = 2.0 * Double(rows) / 3.0
    
    let maxDistance = hypot(centerX1, centerY1) // Considering the distance for the first knob

    var heatmap = [[Double]](repeating: [Double](repeating: 0.0, count: columns), count: rows)

    for y in 0..<rows {
        for x in 0..<columns {
            let distance1 = hypot(Double(x) - centerX1, Double(y) - centerY1)
            let distance2 = hypot(Double(x) - centerX2, Double(y) - centerY2)
            
            // Get the max value between the two knobs for each cell
            let value1 = maxValue * (1.0 - (distance1 / maxDistance))
            let value2 = maxValue * (1.0 - (distance2 / maxDistance))
            
            heatmap[y][x] = min(maxValue, max(0, max(value1, value2)))
        }
    }
    return heatmap
}


let newData = generateHeatmapData(rows: 74, columns: 53, maxValue: 100.0)

/*
func generateHeatmapData(rows: Int, columns: Int) -> [[Double]] {
    var heatmap = [[Double]](repeating: [Double](repeating:0.0, count: columns), count: rows)
    for y in 0..<rows {
        for x in 0..<columns{
            heatmap[y][x] = 0
        }
    }
    return heatmap
}*/
//let newData = generateHeatmapData(rows: 297, columns: 210)



// 生成プログラムを使用して新しいデータを取得
let sampleData = HeatmapData(rows: 74, columns: 53, data: newData)
let viewModel = HeatMapViewModel(heatmap: sampleData)

@main
struct EyeGazeDisplayApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            HeatMapView(viewModel: viewModel, a4Image: Image("Textbook")) // "Textbook"はAssets.xcassetsに追加したイメージの名前になります
        }
    }
}
