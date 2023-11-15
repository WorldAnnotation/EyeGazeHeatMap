//
//  HeatMapView.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import SwiftUI

struct HeatMapView: View {
    var heatmapData: HeatmapData
    var a4Image = Image("TextBook")
    

    var body: some View {
        ZStack {
            a4Image
                .resizable()
                .scaledToFit()
                .frame(width: (420 * 2.116), height: (297 * 2.125))
            
            // Display the heatmap
            VStack(spacing: 0) {
                ForEach(0..<heatmapData.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<heatmapData.columns, id: \.self) { column in
                            Rectangle()
                                .fill(colorForValue(heatmapData.data[row][column]))
                                .frame(width: 12, height: 12)
                                .onTapGesture {
                                    print("Tapped on cell(\(row), \(column))")
                                }
                        }
                    }
                }
            }
        }
        Spacer()
    }
    
    func colorForValue(_ value: Double) -> Color {
        let normalizedValue = value / 100.0 //正規化
        let red = 0.25 + (0.75 * normalizedValue) // 0.25から1.0の範囲で赤を増加させる
        let green = 0.2 * (1.0 - normalizedValue) // 0.2から0.0の範囲で緑を減少させる
        return Color(red: red, green: green, blue: 0.0, opacity: normalizedValue)
    }
}
