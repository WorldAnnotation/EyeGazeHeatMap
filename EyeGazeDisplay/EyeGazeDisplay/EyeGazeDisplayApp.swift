//
//  EyeGazeDisplayApp.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/10/27.
//

import SwiftUI
import Foundation

// 生成プログラムを使用して新しいデータを取得

@main
struct EyeGazeDisplayApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            HeatMapView() // "Textbook"はAssets.xcassetsに追加したイメージの名前になります
        }
    }
}
