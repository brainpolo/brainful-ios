import SwiftUI


struct iPadOSView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var drawingState = DrawingState()
    @State var blocks = [Block]()
    @State private var inputText = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
        
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main column
                VStack {
                    HStack {
                    Button(action: {
                        Task {
                            do {
                                print(drawingState)
                                if drawingState.isCanvasEmpty {
                                    let block = try await api.add_block(string: inputText)
                                    if let lastPinnedIndex = blocks.lastIndex(where: {$0.pinned}) {
                                        blocks.insert(block, at: lastPinnedIndex + 1)
                                    } else {
                                        blocks.insert(block, at:0)
                                    }
                                    inputText = ""
                                } else {  // Drawing
                                    print("drawing submission activate")
                                    
                                }

                            } catch {
                                alertMessage = "Error sending API request: \(error.localizedDescription)"
                                showingAlert = true
                            }
                        }
                    }) {
                        Text("send to brainful")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 30)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(20)
                    }
                    .padding()
                    .buttonStyle(PlainButtonStyle())
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("We are brainfully sorry"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                }
                    
                    TextEditor(text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(height: 150)
                    
                    DrawBoxViewController(drawingState: drawingState)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [8])))
                }.frame(width: geometry.size.width * 0.6) .padding(20)
                Spacer()
                    VStack {
                        BlocksView(blocks: $blocks)
                    }.frame(width: geometry.size.width * 0.4) // End of Vstack
            } // End of VStack
        }  // End of geometry reader
    } // End of body
} // End of struct
