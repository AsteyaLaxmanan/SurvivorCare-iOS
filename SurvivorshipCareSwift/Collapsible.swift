//
//  Collapsible.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


// Collapsible.swift
import SwiftUI

struct Collapsible<Label: View, Content: View>: View {
    @State private var isOpen: Bool = true
    let label: () -> Label
    let content: () -> Content

    init(@ViewBuilder label: @escaping () -> Label,
         @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isOpen) {
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(.top, 8)
        } label: {
            label().font(.headline)
        }
        .tint(.btAccent)
    }
}
