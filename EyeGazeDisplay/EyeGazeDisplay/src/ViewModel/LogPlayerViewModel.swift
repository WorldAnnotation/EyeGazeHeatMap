//
//  LogPlayerViewModel.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/11/15.
//

import Foundation


class LogPlayerViewModel: ObservableObject{
    @Published var logList: [String]?
    @Published var log: [HeatmapData]? // This should store an array of HeatmapData
    @Published var isVisilityList: [[Bool]]?

    private var dbManager: DatabaseManager

    init() {
        dbManager = DatabaseManager()
        getLogList()
    }
    
    func getLogList() {
        dbManager.fetchItemKeys(from: "logs") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let keys):
                    self?.logList = keys
                case .failure(let error):
                    print("Error fetching log keys: \(error.localizedDescription)")
                }    
            }
        }
    }

    func getSpecificLog(with logTitle: String) {
        let path = "logs/\(logTitle)"
        dbManager.fetchData(from: path) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let logData):
                    if let logDataDict = logData as? [String: Any] {
                        var heatmapDataArray: [HeatmapData] = []
                        var cubeVisibilityArray: [[Bool]] = []

                        for (_, value) in logDataDict.sorted(by: { $0.key < $1.key }) {
                            if let logEntry = value as? [String: Any],
                               let logEntries = logEntry["log"] as? [[Int]],
                               let cubeVisibility = logEntry["isCubeVisibility"] as? [Bool] {
                                let rows = logEntries.count
                                let columns = rows > 0 ? logEntries[0].count : 0
                                let heatmapData = HeatmapData(rows: rows, columns: columns, data: logEntries)
                                heatmapDataArray.append(heatmapData)
                                cubeVisibilityArray.append(cubeVisibility)
                            }
                        }
                        self?.log = heatmapDataArray
                        self?.isVisilityList = cubeVisibilityArray
                    }
                case .failure(let error):
                    print("Error fetching log data: \(error.localizedDescription)")
                }
            }
        }
    }

}
