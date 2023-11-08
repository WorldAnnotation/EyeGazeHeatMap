//
//  SelectImageView.swift
//  EyeGazeDisplay
//
//  Created by 河口欣仁 on 2023/11/08.
//

import Foundation
import SwiftUI


struct SelectImageView: View {
    var body: some View {
        VStack{
            Text("Select Image")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 50)
            Rectangle()
                .frame(width: 300, height: 1)
                .foregroundColor(Color.black)
                .padding(.bottom, 50)
        }
    }
}

#Preview {
    SelectImageView()
}
