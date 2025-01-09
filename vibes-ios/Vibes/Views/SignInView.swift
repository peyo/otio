import SwiftUI
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var userService: UserService
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .tint(.appAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Spacer()  // Push content to center
                
                // Logo and Title section
                VStack(spacing: 24) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appAccent)
                    
                    VStack(spacing: 4) {
                        Text("Vibes")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Emotions into insights")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()  // Center between top and button
                
                // Sign in button
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
                
                Spacer()  // Push content to center
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    SignInView()
        .environmentObject(UserService())
}