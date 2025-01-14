import SwiftUI
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var userService: UserService
    @State private var isLoading = false
    @State private var showFirstText = true
    private let firstText = "feeling into insight"
    private let secondText = "insight into sound"
    private let animationDuration = 1.0
    private let displayDuration = 2.0
    
    var body: some View {
        if userService.isAuthenticated {
            EmotionsView()
                .environmentObject(userService)
        } else {
            VStack {
                if isLoading {
                    ProgressView()
                        .tint(.appAccent)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            ZStack {
                                Text(firstText)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .opacity(showFirstText ? 1 : 0)
                                    .animation(.easeInOut(duration: animationDuration), value: showFirstText)
                                
                                Text(secondText)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .opacity(showFirstText ? 0 : 1)
                                    .animation(.easeInOut(duration: animationDuration), value: showFirstText)
                            }
                            .onAppear {
                                startTextSwitching()
                            }
                        }
                        .padding(.top, 40)
                        
                        Button(action: {
                            print("Debug: 🔵 Starting Google Sign In")
                            isLoading = true
                            userService.signInWithGoogle { success in
                                DispatchQueue.main.async {
                                    if !success {
                                        print("Debug: ❌ Sign in failed")
                                    }
                                    isLoading = false
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                    
                                    if let image = UIImage(named: "google-logo") {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: "g.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Text("continue with google")
                                    .font(.subheadline)
                            }
                            .foregroundColor(Color.appAccent)
                            .frame(width: 280, height: 55)
                            .background(Color.appAccent.opacity(0.15))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private func startTextSwitching() {
        Timer.scheduledTimer(withTimeInterval: animationDuration + displayDuration, repeats: true) { _ in
            withAnimation {
                showFirstText.toggle()
            }
        }
    }
}
