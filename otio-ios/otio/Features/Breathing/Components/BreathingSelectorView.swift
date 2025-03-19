import SwiftUI

struct BreathingSelectorView: View {
    @Binding var currentTechnique: BreathingTechnique
    let breathingTechniques: [BreathingTechnique]
    let isActive: Bool
    let geometry: GeometryProxy
    let onTechniqueSelected: (BreathingTechnique, Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 12) {
                    // Add an invisible spacer at the beginning to allow the first card to center
                    Spacer()
                        .frame(width: geometry.size.width / 2 - 50)  // Half screen width minus half card width
                        .opacity(0)
                    
                    ForEach(breathingTechniques, id: \.id) { technique in
                        VStack {
                            BreathingCard(technique: technique, isSelected: currentTechnique.type == technique.type) {
                                if currentTechnique.type != technique.type {
                                    // Calculate minutes for callback
                                    let minutes = isActive ? Int(ceil(Double(0) / 60.0)) : 0
                                    onTechniqueSelected(technique, minutes)
                                    
                                    // Scroll to center the selected technique
                                    withAnimation {
                                        proxy.scrollTo(technique.id, anchor: .center)
                                    }
                                }
                            }
                        }
                        .frame(height: 100)  // Add fixed height like in ListeningView
                        .id(technique.id)  // Add ID for ScrollViewReader
                    }
                    
                    // Add an invisible spacer at the end to allow the last card to center
                    Spacer()
                        .frame(width: geometry.size.width / 2 - 50)  // Half screen width minus half card width
                        .opacity(0)
                }
                .onAppear {
                    // Center the initial technique immediately without animation
                    proxy.scrollTo(currentTechnique.id, anchor: .center)
                }
            }
        }
        .padding(.horizontal)
    }
}