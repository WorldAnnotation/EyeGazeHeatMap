//
//  LogPlayer.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/11/14.
//

import Foundation
import SwiftUI

struct LogPlayerView: View {
    @StateObject var viewModel = LogPlayerViewModel()
    @State private var selectedLogIndex: Int? = 0
    var image = Image("TextBook")

    var body: some View {
        NavigationSplitView {
            // ログのリストを表示するメニューバー
            if let logList = viewModel.logList {
                List(logList.indices, selection: $selectedLogIndex) { index in
                    Text(logList[index]).tag(index)
                }
            } else {
                // ログリストがロードされていない場合
                Text("ログリストをロード中...")
            }
        } detail: {
            // 選択されたログの詳細ビュー
            if let index = selectedLogIndex, let logList = viewModel.logList {
                LogDetailView(log: logList[index], image: image)
            } else {
                Text("ログを選択してください")
            }
        }
        .onAppear {
            viewModel.getLogList()
        }
    }
}

struct LogDetailView: View {
    var log: String
    var image: Image

    var body: some View {
        VStack {
            Text(log)
            image
                .resizable()
                .scaledToFit()
                .frame(width: (420 * 2.1), height: (297 * 2.125))
        }
    }
}
