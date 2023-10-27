//
//  HeatMapView.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import SwiftUI

struct HeatMapView: View {
    @ObservedObject var viewModel: HeatMapViewModel

    var body: some View {
        ZStack{
            VStack(spacing: 0) {  // VStackのスペースを0に設定
                ForEach(0..<viewModel.heatmap.rows, id: \.self) {
                    row in
                    HStack(spacing: 0) {  // HStackのスペースを0に設定
                        ForEach(0..<viewModel.heatmap.columns, id: \.self) {
                            column in
                            Rectangle()
                                .fill(viewModel.colorForValue(viewModel.heatmap.data[row][column]))
                                .frame(width: 35, height: 35)
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
