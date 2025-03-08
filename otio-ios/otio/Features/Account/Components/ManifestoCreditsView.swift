import SwiftUI

struct ManifestoCreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
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
                                        "every interaction should be intuitive and purposeful.",
                                        "no unnecessary complexity or overwhelming options.",
                                        "focus on doing a few things exceptionally well."
                                    ]
                                )
                                
                                manifestoPoint(
                                    title: "mindful design",
                                    details: [
                                        "clean, minimal aesthetics that reduce cognitive load.",
                                        "thoughtful animations that guide rather than distract.",
                                        "space for breath and reflection built into the interface."
                                    ]
                                )
                                
                                manifestoPoint(
                                    title: "personal growth through awareness",
                                    details: [
                                        "help users understand their emotional patterns.",
                                        "transform negative states into opportunities for growth.",
                                        "build emotional intelligence through daily practice."
                                    ]
                                )
                                
                                manifestoPoint(
                                    title: "accessible wellness",
                                    details: [
                                        "make meditation and breathing exercises approachable.",
                                        "remove barriers to entry for mindfulness practices.",
                                        "create a judgment-free space for all experience levels."
                                    ]
                                )
                                
                                manifestoPoint(
                                    title: "respect for time",
                                    details: [
                                        "value users' time and attention.",
                                        "no endless scrolling or addictive patterns.",
                                        "quick access to tools when needed most."
                                    ]
                                )
                                
                                manifestoPoint(
                                    title: "privacy by design",
                                    details: [
                                        "protect emotional data as sensitive information.",
                                        "no social comparison or sharing features.",
                                        "create a truly personal space for wellbeing."
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
                                ForEach(["chris cardillo", "liz yoon", "matt klein", "mike sim", "mike yi", "nick brennan", "paul kang"], id: \.self) { name in
                                    Text(name)
                                        .font(.custom("IBMPlexMono-Light", size: 15))
                                        .foregroundColor(.secondary)
                                }
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
        .navigationBarBackButtonHidden()
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
                            .foregroundColor(.secondary)
                            .frame(width: 12, alignment: .leading)
                        
                        Text(detail)
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.secondary)
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