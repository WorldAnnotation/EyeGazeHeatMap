//
//  HeatMapView.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import SwiftUI

struct HeatMapView: View {
    @ObservedObject var viewModel: HeatMapViewModel
    var a4Image: Image
    
    var body: some View {
        ZStack {
            // 画像を表示
            a4Image
                .resizable()
                .scaledToFit()
                .frame(width: (297 * 4.3), height: (210 * 4.3))
            
            // ヒートマップを表示
            VStack(spacing: 0) {
                ForEach(0..<viewModel.heatmap.rows, id: \.self) {
                    row in
                    HStack(spacing: 0) {
                        ForEach(0..<viewModel.heatmap.columns, id: \.self) {
                            column in
                            Rectangle()
                                .fill(viewModel.colorForValue(viewModel.heatmap.data[row][column]))
                                .frame(width: 12, height: 12)
                                .onTapGesture{
                                    print("Tapped on cell(\(row), \(column)")
                                }
                        }
                    }
                }
            }
        }
    }
}
