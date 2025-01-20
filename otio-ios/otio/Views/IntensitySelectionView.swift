import SwiftUI

struct IntensitySelectionView: View {
    let emotion: String
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(emojiFor(emotion))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)

                        Text("how \(emotion.lowercased()) are you feeling?")
                            .font(.custom("NewHeterodoxMono-Book", size: 17))
                    }
                    .padding(.top, 40)

                    HStack(spacing: 20) {
                        ForEach(1...3, id: \.self) { intensity in
                            Button {
                                onSelect(intensity)
                                dismiss()
                            } label: {
                                Rectangle()
                                    .fill(Color.forEmotion(emotion).opacity(Double(intensity) / 3.0))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Text("\(intensity)")
                                                .font(.custom("NewHeterodoxMono-Book", size: 22))
                                                .fontWeight(.medium)
                                            Text(intensityLabel(for: intensity))
                                                .font(.custom("NewHeterodoxMono-Book", size: 12))
                                                .fontWeight(.medium)
                                        }
                                            .foregroundColor(.primary)
                                    )
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("select intensity")
                        .font(.custom("NewHeterodoxMono-Book", size: 22))
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
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

    private func intensityLabel(for intensity: Int) -> String {
        switch intensity {
        case 1: return "a little"
        case 2: return "somewhat"
        case 3: return "very"
        default: return ""
        }
    }
}
