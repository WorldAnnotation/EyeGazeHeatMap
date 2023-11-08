//
//  HeatMapViewModel.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

class HeatMapViewModel: ObservableObject {
    @Published var heatMap: HeatmapData?

    private var dbManager: DatabaseManager
    private var timerSubscription: AnyCancellable?

    init() {
        dbManager = DatabaseManager()
        startFetchingData()
    }

    func startFetchingData() {
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.fetchData()
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
        if let formattedData = formatData(with: fetchedData),
           let heatMapArray = formattedData["heat_map"] as? [[Double]] {
            // We already have rows and columns information within the heatMapArray.
            let rows = heatMapArray.count
            let columns = heatMapArray.first?.count ?? 0
            let heatmapData = HeatmapData(rows: rows, columns: columns, data: heatMapArray)
            
            // Assigning the fetched and formatted heatmap data to the @Published heatMap property
            heatMap = heatmapData
        }
    }
    
    private func formatData(with fetchedData: Any) -> [String: Any]? {
        // まずは、受け取ったデータをNSDictionary型にキャストします。
        if let dictionary = fetchedData as? [String: Any] {
            // キャストが成功したら、heat_mapとタイムスタンプの値を取り出します。
            if let heatMapArray = dictionary["heat_map"] as? [[Double]], // heat_mapは2次元配列としてキャスト
               let lastUpdate = dictionary["last_update"] as? String, // タイムスタンプはStringとしてキャスト
               let startTime = dictionary["start_time"] as? String {
                // 成功した場合、処理を実行します。
                print("Heat Map Array: \(heatMapArray)")
                print("Last Update: \(lastUpdate)")
                print("Start Time: \(startTime)")
                
                return dictionary;
            } else {
                print("Data casting failed")
            }
        } else {
            print("Invalid data structure")
        }
        return nil;
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
