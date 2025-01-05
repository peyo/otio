import SwiftUI

struct ConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isButtonPressed = false
    @State private var isConnected = true
    @State private var connectedUsername = "Peaceful_Whale_42"
    @State private var connectedLocation = "Tokyo, Japan"
    @State private var isBreathing = false
    @State private var connectionStatus: ConnectionStatus = .searching
    
    // Add enum for connection states
    enum ConnectionStatus {
        case searching
        case connecting
        case connected
        case disconnected
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Title and Subtitle
            VStack(spacing: 2) {
                Text("Connect")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Share your presence")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
                .frame(height: 32)
            
            // Connection Status
            VStack(spacing: 32) {
                // Status Indicator
                switch connectionStatus {
                case .searching:
                    ProgressView("Scanning the vibes... ✨")
                        .tint(.appAccent)
                        .transition(.opacity.combined(with: .scale))
                case .connecting:
                    ProgressView("Weaving a connection... 🧵")
                        .tint(.appAccent)
                        .transition(.opacity.combined(with: .scale))
                case .connected:
                    // Glowing Square with breathing
                    Rectangle()
                        .fill(Color.appAccent.opacity(isButtonPressed ? 0.8 : 0.3))
                        .frame(width: 140, height: 140)
                        .cornerRadius(20)
                        .animation(.easeInOut(duration: 0.3), value: isButtonPressed)
                        .shadow(color: Color.appAccent.opacity(0.2), radius: 10)
                        .scaleEffect(isBreathing ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                            value: isBreathing
                        )
                        .onAppear {
                            isBreathing = true
                        }
                    
                    // Connected User Details
                    VStack(spacing: 12) {
                        Text("You are connected to:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text(connectedUsername)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text(connectedLocation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                case .disconnected:
                    Text("Connection needs a breather... 🌬️")
                        .foregroundColor(.secondary)
                        .padding()
                        .transition(.opacity.combined(with: .scale))
                }
            }
            
            Spacer()
            
            // Connection Button - updates based on status
            Button {
                // Will implement connection logic later
            } label: {
                Text(connectionButtonTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appAccent)
                            .shadow(color: Color.appAccent.opacity(0.2), radius: 5, y: 2)
                    )
            }
            .pressAction(onPress: { pressed in
                withAnimation {
                    isButtonPressed = pressed
                }
                // Add haptic feedback
                if pressed {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            })
        }
        .padding(.horizontal)
        .padding(.bottom)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appAccent)
                }
            }
        }
        
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Cycle through states
                    switch connectionStatus {
                    case .searching:
                        connectionStatus = .connecting
                    case .connecting:
                        connectionStatus = .connected
                    case .connected:
                        connectionStatus = .disconnected
                    case .disconnected:
                        connectionStatus = .searching
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.appAccent)
                }
            }
        }
        #endif
        
        .animation(.easeInOut(duration: 0.3), value: connectionStatus)
    }
    
    // Button title based on connection status
    private var connectionButtonTitle: String {
        switch connectionStatus {
        case .searching:
            return "Searching"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Hold to Connect"
        case .disconnected:
            return "Try Again"
        }
    }
}

// Custom modifier for press and hold gesture
struct PressActions: ViewModifier {
    var onPress: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress(true) }
                    .onEnded { _ in onPress(false) }
            )
    }
}

extension View {
    func pressAction(onPress: @escaping (Bool) -> Void) -> some View {
        modifier(PressActions(onPress: onPress))
    }
}

#Preview {
    NavigationView {
        ConnectionView()
    }
}