//
//  LogPlayerViewModel.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/11/15.
//

import Foundation


class LogPlayerViewModel: ObservableObject{
    @Published var logList: [String]?

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

    func getSpecificLog(with LogTitle: String) {

    }
}
