//
//  HeatMapView.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import SwiftUI

struct HeatMapView: View {
    @StateObject var viewModel = HeatMapViewModel()
    var a4Image = Image("TextBook")
    
    var body: some View {
        ZStack {
            // Display the image
            a4Image
                .resizable()
                .scaledToFit()
                .frame(width: (420 * 4.3), height: (297 * 4.3))
            
            // Display the heatmap
            if let heatMapData = viewModel.heatMap {
                VStack(spacing: 0) {
                    ForEach(0..<heatMapData.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<heatMapData.columns, id: \.self) { column in
                                Rectangle()
                                    .fill(viewModel.colorForValue(heatMapData.data[row][column]))
                                    .frame(width: 12, height: 12)
                                    .onTapGesture {
                                        print("Tapped on cell(\(row), \(column))")
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
}
