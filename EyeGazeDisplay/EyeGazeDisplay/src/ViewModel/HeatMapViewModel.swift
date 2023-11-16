//
//  HeatMapViewModel.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import Foundation
import SwiftUI
import Combine

class HeatMapViewModel: ObservableObject {
    @Published var heatMap: HeatmapData?
    @Published var isVisibilityList: [Bool]?

    private var dbManager: DatabaseManager
    private var timerSubscription: AnyCancellable?
    private var visibilitytimerSubscription: AnyCancellable?


    init() {
        dbManager = DatabaseManager()
        startFetchingData()
    }

    func startFetchingData() {
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.fetchData()
        }
        visibilitytimerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.fetchVisibilityData()
        }
    }
    
    private func fetchVisibilityData() {
        dbManager.fetchData(from: "isVisibleList") { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let fetchedData):
                    if let visibilityData = fetchedData as? [Bool] {
                        self.isVisibilityList = visibilityData
                    } else {
                        print("Type mismatch: expected a Bool from fetched data.")
                    }
                case .failure(let error):
                    print("Error fetching data: \(error.localizedDescription)")
                }
            }
        }
    }


    private func fetchData() {
        dbManager.fetchData(from: "images/image1") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedData):
                    // ここでフェッチされたデータをgenerateHeatMapに渡す
                    self?.generateHeatMap(with: fetchedData)
                case .failure(let error):
                    print("Error fetching data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // この関数をあなたのFirebaseからのデータフェッチが完了した時点で呼び出します。
    private func generateHeatMap(with fetchedData: Any) {
        if let heatMapArray = fetchedData as? [[Double]] {
            let rows = heatMapArray.count
            let columns = heatMapArray.first?.count ?? 0
            let heatmapData = HeatmapData(rows: rows, columns: columns, data: heatMapArray)
            
            // Assigning the fetched and formatted heatmap data to the @Published heatMap property
            heatMap = heatmapData
        } else {
            print("Invalid data structure")
        }
    }

    // オブジェクトが解放されたときにタイマーを停止
    deinit {
        timerSubscription?.cancel()
    }
    
    func colorForValue(_ value: Double) -> Color {
        let normalizedValue = value / 100.0 //正規化
        let red = 0.25 + (0.75 * normalizedValue) // 0.25から1.0の範囲で赤を増加させる
        let green = 0.2 * (1.0 - normalizedValue) // 0.2から0.0の範囲で緑を減少させる
        return Color(red: red, green: green, blue: 0.0, opacity: normalizedValue)
    }
}
