import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

class HeatMapViewModel: ObservableObject {
    @Published var heatMap: HeatmapData?
    @Published var isVisibilityList: [Bool]?

    private var dbManager: DatabaseManager
    private var timerSubscription: AnyCancellable?
    private var visibilitytimerSubscription: AnyCancellable?
    var dbRef: DatabaseReference

    init() {
        dbManager = DatabaseManager()
        dbRef = Database.database().reference()
        fetchData(from: "images/image2", completion: updateHeatMap)
        fetchData(from: "isVisibleList", completion: updateVisibilityList)
    }

    private func fetchData<T>(from path: String, completion: @escaping (T) -> Void) {
        dbManager.fetchData(from: path) { result in
            switch result {
                case .success(let data):
                    if let castedData = data as? T {
                        completion(castedData)
                    }
                case .failure(let error):
                    print("Error fetching data: \(error.localizedDescription)")
            }
        }
    }


    private func updateHeatMap(with data: [[String: Int]]) {
        var updatedData = Array(repeating: Array(repeating: 0, count: Constants.columns), count: Constants.rows)

        for entry in data {
            if let x = entry["x"], let y = entry["y"], let value = entry["value"], isValidCoordinate(x: x, y: y) {
                updatedData[y][x] = value
            }
        }

        heatMap = HeatmapData(rows: Constants.rows, columns: Constants.columns, data: updatedData)
    }

    private func updateVisibilityList(with data: [Bool]) {
        isVisibilityList = data
    }

    private func isValidCoordinate(x: Int, y: Int) -> Bool {
        return x >= 0 && x < Constants.columns && y >= 0 && y < Constants.rows
    }

    func colorForValue(_ value: Double) -> Color {
        let normalizedValue = value / Constants.maxValue
        let red = Constants.minRed + (Constants.maxRed - Constants.minRed) * normalizedValue
        let green = Constants.maxGreen * (1.0 - normalizedValue)
        return Color(red: red, green: green, blue: 0.0, opacity: normalizedValue)
    }

    private struct Constants {
        static let rows = 60
        static let columns = 80
        static let maxValue = 100.0
        static let minRed = 0.25
        static let maxRed = 1.0
        static let maxGreen = 0.2
    }
}
