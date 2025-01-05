import SwiftUI
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        VStack(spacing: 40) {
            // Logo/Brand Section
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.appAccent)
                
                Text("Welcome to Vibes")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Turn emotions into insights")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Sign In Button
            Button(action: {
                userService.signInWithGoogle()
            }) {
                HStack(spacing: 12) {
                    if let image = UIImage(named: "google-logo") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(6)
                            .background(Color.white)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "g.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    
                    Text("Continue with Google")
                        .font(.headline)
                        .foregroundColor(Color.appAccent)
                }
                .frame(width: 280, height: 55)
                .background(Color.appAccent.opacity(0.15))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            }
            .padding()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    SignInView()
        .environmentObject(UserService())  // Add this because view uses @EnvironmentObject
}