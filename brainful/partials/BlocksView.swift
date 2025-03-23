import SwiftUI

struct BlocksView: View {
    @EnvironmentObject var appState: AppState
    @Binding var blocks: [Block]
    @State private var selectedBlock: Block? = nil
    @State private var showingLuidCopiedAlert = false
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var syncStatus: String? = nil
    @State private var showingSyncMessage = false
    
    var filteredBlocks: [Block] {
        // Sort blocks with pinned first, then by last edited date
        let sorted = blocks.sorted {
            if $0.pinned && !$1.pinned {
                return true
            } else if !$0.pinned && $1.pinned {
                return false
            } else {
                return ($0.last_edited ?? Date()) > ($1.last_edited ?? Date())
            }
        }
        
        // Then filter by search text if needed
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { block in
                block.slug.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Main content
                VStack {
                    // Custom scroll view with offset tracking
                    ScrollView {
                        VStack(spacing: 0) {
                            // Geometry reader to track scroll position
                            GeometryReader { geometry in
                                Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                                                      value: geometry.frame(in: .named("scrollView")).minY)
                            }
                            .frame(height: 0)

                            // Top padding
                            Spacer().frame(height: 75)
                                              
                            
                            LazyVStack(spacing: 16) {
                              ForEach(filteredBlocks) { block in
                                  NavigationLink(
                                      destination: BlockView(blockLuid: block.luid),
                                      label: {
                                          BlockCardView(block: block, onCopyLuid: {
                                              UIPasteboard.general.string = block.luid
                                              selectedBlock = block
                                              showingLuidCopiedAlert = true
                                          })
                                      }
                                  )
                                  .buttonStyle(PlainButtonStyle()) // Prevent navigation link styling
                              }
                          }
                          .padding(.horizontal)
                          .padding(.bottom, 20)
                        }
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
                    .refreshable {
                        do {
                            let result = try await api.get_blocks()
                            self.blocks = result.blocks
                            self.syncStatus = result.status.message
                            
                            // Show message
                            withAnimation {
                                self.showingSyncMessage = true
                            }
                            
                            // Auto-hide after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation {
                                    self.showingSyncMessage = false
                                }
                            }
                        } catch {
                            print("Error getting blocks")
                        }
                    }
                }
                
                // Top fade effect
                VStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemBackground), Color(.systemBackground).opacity(0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                    
                    Spacer()
                    
                    // Bottom fade effect
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                }
                .allowsHitTesting(false)
                
                // Glass-effect search bar
                VStack {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    Spacer()
                }
                .background(
                    // Blurred glass effect background that fades as you scroll
                    Color(.systemBackground)
                        .opacity(scrollOffset < 0 ? 0.9 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: scrollOffset < 0)
                )
                
                // Sync status message (slide-in banner)
                if let status = syncStatus, showingSyncMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                            Text(status)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    showingSyncMessage = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 0)
                        )
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    let result = try await api.get_blocks()
                    self.blocks = result.blocks
                    self.syncStatus = result.status.message
                    
                    // Show message
                    withAnimation {
                        self.showingSyncMessage = true
                    }
                    
                    // Auto-hide after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            self.showingSyncMessage = false
                        }
                    }
                } catch {
                    print("Error getting blocks")
                }
            }
            .alert("LUID Copied", isPresented: $showingLuidCopiedAlert) {
                Button("OK") {}
            } message: {
                Text("The LUID \(selectedBlock?.luid ?? "") has been copied to the clipboard.")
            }
        }
    }
}

// Modern glass-effect search bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("Search by slug", text: $text)
                .padding(10)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

// Card view for individual blocks
struct BlockCardView: View {
    let block: Block
    let onCopyLuid: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                // Block type badge
                Text(block.type)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeBadgeColor(for: block.type))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Spacer()
                
                // Pinned indicator
                if block.pinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(block.slug)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 2)
            
            Divider()
                .padding(.vertical, 2)
            
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .contextMenu {
            Button(action: onCopyLuid) {
                Label("Copy LUID", systemImage: "doc.on.doc")
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
        default: return .blue
        }
    }
}

// Preference key to track scroll position
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Helper function to format dates
func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}
