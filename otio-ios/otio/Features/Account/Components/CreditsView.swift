import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {                   
                    // Contributors Section
                    VStack(spacing: 16) {
                        Text("contributors")
                            .font(.custom("IBMPlexMono-Light", size: 17))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ForEach(["chris cardillo", "liz yoon", "matt klein", "mike sim", "nick brennan", "paul kang"], id: \.self) { name in
                                Text(name)
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("credits")
                    .font(.custom("IBMPlexMono-Light", size: 22))
                    .fontWeight(.semibold)
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