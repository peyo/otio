import SwiftUI

struct RefreshControl: View {
    let coordinateSpace: CoordinateSpace
    let onRefresh: () async -> Void
    let isInCooldown: Bool
    
    @State private var offset: CGFloat = 0
    @State private var isRefreshing = false
    
    var body: some View {
        GeometryReader { geo in
            if offset > 0 {
                ProgressView()
                    .tint(.appAccent)
                    .frame(width: geo.size.width, height: offset)
            }
        }
        .frame(height: 0)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ScrollViewOffsetPreferenceKey.self,
                        value: geo.frame(in: coordinateSpace).minY
                    )
            }
        )
        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { offset in
            self.offset = offset
            
            if offset > 50 && !isRefreshing && !isInCooldown {
                Task { @MainActor in
                    isRefreshing = true
                    await onRefresh()
                    isRefreshing = false
                }
            }
        }
    }
}

private struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
} 
