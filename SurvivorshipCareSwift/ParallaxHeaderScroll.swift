// ParallaxHeaderView.swift
import SwiftUI

struct ParallaxHeaderScroll<Header: View, Content: View>: View {
    let headerHeight: CGFloat
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                ZStack(alignment: .top) {
                    // HEADER sits behind and ignores touches
                    GeometryReader { g in
                        let y = g.frame(in: .global).minY
                        header()
                            .frame(height: headerHeight + max(0, y))
                            .offset(y: -max(0, y))
                    }
                    .frame(height: headerHeight)
                    .allowsHitTesting(false)   // <-- important
                    .zIndex(0)

                    // CONTENT sits above and receives taps
                    VStack(spacing: 16) {
                        Color.clear.frame(height: headerHeight + 24) // push content below header
                        content()
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                    }
                    .zIndex(1)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color.btBg)
        }
    }
}
