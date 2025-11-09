//
//  Theme.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//

// Theme.swift
import SwiftUI

extension Color {
    // RN accent looked like a teal / cyan #0a7ea4
    static let btAccent = Color(red: 0x0A/255, green: 0x7E/255, blue: 0xA4/255)
    static let btBg = Color(uiColor: .systemBackground)
    static let btMuted = Color.secondary
}

struct BTTitle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: 34, weight: .bold, design: .rounded))
    }
}
struct BTSubtitle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: 20, weight: .semibold))
              .foregroundStyle(Color.btAccent)
    }
}
struct BTLink: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: 16, weight: .semibold))
              .foregroundStyle(Color.btAccent)
              .underline()
    }
}
extension View {
    func btTitle() -> some View { modifier(BTTitle()) }
    func btSubtitle() -> some View { modifier(BTSubtitle()) }
    func btLink() -> some View { modifier(BTLink()) }
}
