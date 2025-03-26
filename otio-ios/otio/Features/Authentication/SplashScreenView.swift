import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var userService: UserService
    @State private var isActive = false
    @State private var scaleEffect: CGFloat = 1.0
    @State private var resetNavigation = UUID()

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
                
            if isActive {
                Group {
                    if userService.isAuthenticated {
                        EmotionsView()
                            .environmentObject(userService)
                            .id(resetNavigation) // Force view refresh on navigation reset
                    } else {
                        SignInView()
                            .environmentObject(userService)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 51))
                        .foregroundColor(.primary)
                        .scaleEffect(scaleEffect)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                scaleEffect = 1.2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    isActive = true
                                }
                            }
                        }
                    
                    Spacer()
                }
            }
        }
        .onChange(of: userService.isAuthenticated) { _ in
            // Reset navigation when auth state changes
            resetNavigation = UUID()
        }
    }
}