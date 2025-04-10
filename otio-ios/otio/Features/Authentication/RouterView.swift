import SwiftUI

struct RouterView: View {
    @EnvironmentObject var userService: UserService
    @StateObject private var emotionService = EmotionService.shared
    @State private var resetNavigation = UUID()
    
    var body: some View {
        Group {
            if userService.isAuthenticated {
                EmotionsView()
                    .environmentObject(userService)
                    .environmentObject(emotionService)
                    .id(resetNavigation)
            } else {
                SignInView()
                    .environmentObject(userService)
            }
        }
        .onChange(of: userService.isAuthenticated) { _ in
            // Reset navigation when auth state changes
            resetNavigation = UUID()
        }
    }
}