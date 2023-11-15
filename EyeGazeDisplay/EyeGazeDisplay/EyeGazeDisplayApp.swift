//
//  EyeGazeDisplayApp.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import SwiftUI
import Foundation


@main
struct EyeGazeDisplayApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}
