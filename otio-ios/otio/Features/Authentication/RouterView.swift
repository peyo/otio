import SwiftUI

struct RouterView: View {
    @EnvironmentObject var userService: UserService
    @State private var resetNavigation = UUID()
    
    var body: some View {
        Group {
            if userService.isAuthenticated {
                EmotionsView()
                    .environmentObject(userService)
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