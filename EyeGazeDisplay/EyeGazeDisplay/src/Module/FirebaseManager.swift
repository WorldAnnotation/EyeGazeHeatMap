import Foundation
import FirebaseDatabase

class DatabaseManager {
    
    private var dbRef: DatabaseReference
    private var valueHandle: DatabaseHandle?
    private var lastFetchTime: Date?

    init() {
        self.dbRef = Database.database().reference()
        self.lastFetchTime = nil
    }

    func startObservingData(from path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        valueHandle = dbRef.child(path).observe(.value, with: { snapshot in
            if let lastFetch = self.lastFetchTime, Date().timeIntervalSince(lastFetch) < 1 {
                return
            }
                        
            if let value = snapshot.value {
                print("Fetched data \(Date())")
                self.lastFetchTime = Date()
                completion(.success(value))
            } else {
                completion(.failure(NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data available at the given path."])))
            }
        }) { error in
            completion(.failure(error))
        }
    }

    func stopObservingData() {
        if let handle = valueHandle {
            dbRef.removeObserver(withHandle: handle)
        }
    }
}
