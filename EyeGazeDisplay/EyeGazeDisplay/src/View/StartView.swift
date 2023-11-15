//
//  StartView.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/11/14.
//

import SwiftUI

struct StartView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("LiveView") {
                    LiveView();
                }
                NavigationLink("LogPlayerView") {
                    LogPlayerView();
                }
            }
            .navigationTitle("EyeGazeDisplay");    
        }
    }
}
