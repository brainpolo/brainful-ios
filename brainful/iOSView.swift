import SwiftUI
import UniformTypeIdentifiers

struct iOSView: View {
    
    @State var showSidebar = false
    @State var offset: CGFloat = 0
    @State var lastStoredOffset: CGFloat = 0
    
    var body: some View {
        
        let sidebarWidth = getRect().width
        
        NavigationView {
            HStack(spacing: 0) {
                
                Sidebar(showSidebar: $showSidebar) // Sidebar
                
                VStack(spacing: 0) {
                 HomeView()
                } // End of VStack
            } // End of HStack (sidebar + main view container)
            .frame(width: getRect().width + sidebarWidth)
            .offset(x: -sidebarWidth / 2)
            .offset(x: offset)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden)
            .contentShape(Rectangle())
            .gesture(DragGesture()
                .onChanged { value in
                    let touchLocation = value.location
                    if touchLocation.x > sidebarWidth {
                        if !showSidebar && value.translation.width > 100 {
                            showSidebar = true
                        } else if showSidebar && value.translation.width < -100 {
                            showSidebar = false
                        }
                    }
                }
            )
        } // End of nav view
        .animation(.easeOut, value: offset == 0)
        .onChange(of: showSidebar) { newValue in
            if showSidebar && offset == 0 {
                offset = sidebarWidth
                lastStoredOffset = offset
            }
            if !showSidebar && offset == sidebarWidth {
                offset = 0
                lastStoredOffset = 0
            }
        }
    } // End of body
    
}
