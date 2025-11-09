//
//  IconSymbol.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


// IconSymbol.swift
import SwiftUI

struct IconSymbol: View {
    let name: String
    var size: CGFloat = 24
    var color: Color? = nil

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color ?? .primary)
    }
}
