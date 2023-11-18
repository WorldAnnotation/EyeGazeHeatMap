//
//  FirebaseManager.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import Foundation
import FirebaseDatabase

class DatabaseManager {
    
    private var dbRef: DatabaseReference

    init() {
        // DatabaseReferenceのインスタンスを取得
        self.dbRef = Database.database().reference()
    }
    
    // 指定したパスのデータを取得するメソッド
    func fetchData(from path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        dbRef.child(path).observe(.value, with: { snapshot in
            if let value = snapshot.value {
                // 成功した場合はvalueを返す
                completion(.success(value))
            } else {
                // snapshotが存在しない場合はエラーを返す
                completion(.failure(NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data available at the given path."])))
            }
        }) { error in
            // エラーが発生した場合はエラーを返す
            completion(.failure(error))
        }
    }
    
    func fetchItemKeys(from path: String, completion: @escaping (Result<[String], Error>) -> Void) {
        dbRef.child(path).observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data available at the given path."])))
                return
            }

            let keys = Array(value.keys)
            completion(.success(keys))
        }) { error in
            completion(.failure(error))
        }
    }
}
