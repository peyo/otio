import SwiftUI

struct ManifestoCreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Manifesto Section
                            ManifestoCreditCard(
                                title: "manifesto",
                                content: AnyView(
                                    Group {
                                        manifestoPoint(
                                            title: "simplicity over features",
                                            details: [
                                                "every interaction should be intuitive and purposeful."
                                            ]
                                        )
                                        
                                        manifestoPoint(
                                            title: "mindful design",
                                            details: [
                                                "clean, minimal aesthetics that reduce cognitive load."
                                            ]
                                        )
                                        
                                        manifestoPoint(
                                            title: "personal growth through awareness",
                                            details: [
                                                "help users understand their emotional patterns."
                                            ]
                                        )
                                        
                                        manifestoPoint(
                                            title: "accessible wellness",
                                            details: [
                                                "remove barriers to entry for mindfulness practices."
                                            ]
                                        )
                                        
                                        manifestoPoint(
                                            title: "respect for time",
                                            details: [
                                                "no endless scrolling or addictive patterns."
                                            ]
                                        )
                                        
                                        manifestoPoint(
                                            title: "privacy by design",
                                            details: [
                                                "protect emotional data as sensitive information."
                                            ]
                                        )
                                    }
                                )
                            )
                            
                            // Contributors Section
                            ManifestoCreditCard(
                                title: "contributors",
                                content: AnyView(
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("chris, liz, matt, mike, mike, nick, paul")
                                            .font(.custom("IBMPlexMono-Light", size: 15))
                                            .foregroundColor(.primary)
                                    }
                                )
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("manifesto / credits")
                            .font(.custom("IBMPlexMono-Light", size: 22))
                            .fontWeight(.semibold)
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.primary)
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.width > 100 {
                                dismiss()
                            }
                        }
                )
            }
        }
    }
    
    private func manifestoPoint(title: String, details: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("IBMPlexMono-Light", size: 15))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(details, id: \.self) { detail in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                            .frame(width: 12, alignment: .leading)
                        
                        Text(detail)
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct ManifestoPoint {
    let title: String
    let details: [String]
}