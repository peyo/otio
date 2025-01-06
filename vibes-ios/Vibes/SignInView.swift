import SwiftUI
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.appAccent)
                
                VStack(spacing: 4) {
                    Text("Welcome to Vibes")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Turn emotions into insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Sign in button
            Button(action: {
                print("Debug: 🔵 Starting Google Sign In")
                userService.signInWithGoogle()
            }) {
                HStack(spacing: 12) {
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
                    
                    Text("Continue with Google")
                        .font(.headline)
                }
                .foregroundColor(Color.appAccent)
                .frame(width: 280, height: 55)
                .background(Color.appAccent.opacity(0.15))
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    SignInView()
        .environmentObject(UserService())  // Add this because view uses @EnvironmentObject
}