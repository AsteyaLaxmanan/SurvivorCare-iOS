//
//  ReportView.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


// ReportView.swift
import SwiftUI

struct ReportView: View {
    let text: String
    var body: some View {
        ScrollView {
            Text(text)
                .font(.body)
                .padding()
        }
        .navigationTitle("Daily Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}
