import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var userService: UserService
    @State private var isActive = false
    @State private var scaleEffect: CGFloat = 1.0

    var body: some View {
        ZStack {
            if isActive {
                SignInView()
                    .environmentObject(userService)
            } else {
                VStack {
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 51))
                        .foregroundColor(.black)
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
    }
}
