import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userService = UserService.shared
    @State private var shouldShowSignIn = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            if shouldShowSignIn {
                SignInView()
                    .environmentObject(userService)
            } else {
                VStack(spacing: 32) {
                    // User Information
                    VStack(alignment: .leading, spacing: 24) {
                        if let email = userService.userEmail {
                            Text("email address: \(email)")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                        }
                        
                        if let joinDate = userService.joinDate {
                            Text("join date: \(formatDate(joinDate))")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                        }
                        
                        Text("total breath time: \(formatMinutes(userService.totalBreathingMinutes))")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                        
                        Text("total meditation time: \(formatMinutes(userService.totalMeditationMinutes))")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Credits and Logout Buttons
                    VStack(spacing: 24) {
                        NavigationLink {
                            ManifestoCreditsView()
                        } label: {
                            Text("manifesto / credits")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.appAccent)
                        }
                        
                        Button(action: {
                            userService.signOut()
                            shouldShowSignIn = true
                        }) {
                            Text("log out")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.appAccent)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("account")
                            .font(.custom("IBMPlexMono-Light", size: 22))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.appAccent)
                        }
                    }
                }
            }
        }
        .onAppear {
            userService.fetchUserStats()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"  // Use custom format
        let formattedDate = formatter.string(from: date)
        return formattedDate.lowercased()  // Convert to lowercase
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

#Preview {
    AccountView()
}