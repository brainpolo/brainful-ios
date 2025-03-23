import SwiftUI

struct BlockView: View {
    let blockLuid: String
    @State private var block: Block?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let errorMsg = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("Error loading block")
                        .font(.headline)
                    
                    Text(errorMsg)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            } else if let block = block {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Type badge and pin indicator
                        HStack {
                            Text(block.type)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(typeBadgeColor(for: block.type))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            if block.pinned {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        // Block content
                        Text(block.text ?? "No content")
                            .font(.body)
                        
                        Divider()
                        
                        // Metadata
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LUID: \(block.luid)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Created:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(formattedDate(block.created_timestamp ?? Date()))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Last Edited:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(formattedDate(block.last_edited ?? Date()))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationBarTitle(block.slug, displayMode: .inline)
            } else {
                Text("Block not found")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadBlock()
        }
    }
    
    private func loadBlock() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedBlock = try await api.get_block(block_luid: blockLuid)
                DispatchQueue.main.async {
                    self.block = loadedBlock
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                print("Error loading block: \(error)")
            }
        }
    }
    
    // Helper function to determine badge color based on block type
    private func typeBadgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "note": return .blue
        case "task": return .green
        case "event": return .purple
        case "link": return .orange
        case "code": return .gray
        case "idea": return .indigo
        default: return .blue
        }
    }
}
