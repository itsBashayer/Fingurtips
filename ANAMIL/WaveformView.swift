//
//  WaveformView.swift
//  AnamelDemo
//
//  Created by Joury on 05/11/1446 AH.
//

import SwiftUI
import AVFoundation

struct  WaveformView: View {
   // @Binding var micLevel: Float
    var micLevel: Float
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { i in
                Capsule()
                    .fill(Color.blue)
                    .frame(width: 3, height: CGFloat(max(2, CGFloat(micLevel) * 40 * CGFloat.random(in: 0.7...1.3))))
            }
        }
        .frame(height: 40)
        .animation(.easeInOut(duration: 0.2), value: micLevel)
    }
}
