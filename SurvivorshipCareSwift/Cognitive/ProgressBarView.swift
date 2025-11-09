//
//  ProgressBarView.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


import SwiftUI

struct ProgressBarView: View {
    var progress: Double // 0..1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(Color.btAccent)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
                    .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
        .frame(height: 10)
        .accessibilityLabel("progress")
    }
}
