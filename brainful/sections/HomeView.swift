import SwiftUI
import UniformTypeIdentifiers
import QuickLook

class FilePreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?

    init(previewItemURL: URL?, previewItemTitle: String? = nil) {
        self.previewItemURL = previewItemURL
        self.previewItemTitle = previewItemTitle
    }
}

struct FilePreview: UIViewControllerRepresentable {
    let previewItem: QLPreviewItem

    func makeUIViewController(context: Context) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        return previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(previewItem: previewItem)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let previewItem: QLPreviewItem

        init(previewItem: QLPreviewItem) {
            self.previewItem = previewItem
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return previewItem
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    @State private var blocks: [Block] = []
    @State private var alertMessage = ""
    @State private var showingAlert = false

    // Text data
    @State var showTextField = false
    @State private var inputText = ""

    // File data
    @State var showFileField = false
    @State private var isFilePickerPresented = false
    @State private var selectedFile: URL?
    @State private var uploadTask: Task<Block?, Never>?
    @State private var filePreviewItem: QLPreviewItem? // File preview item

    var body: some View {
        VStack {
            // New block previews (Text and file)
            if showFileField, let previewItem = filePreviewItem {
                FilePreview(previewItem: previewItem)
                    .frame(height: 200)
                    .padding(.all, 20)
                    .cornerRadius(20)
            }
            if showTextField { // New node text input box
                TextEditor(text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .frame(height: 150)
                    .padding(.all, 20)
                    .cornerRadius(35)
            }

            BlocksView(blocks: $blocks) // Pass blocks as a binding to BlocksView

            HStack { // Custom tab bar
                Button(action: {
                    isFilePickerPresented = true
                }) {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                    }
                }
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .padding(.vertical, 15)
                .padding(.horizontal, 15)
                .buttonStyle(PlainButtonStyle())
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]),
                                   startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(30)
                .fileImporter(
                    isPresented: $isFilePickerPresented,
                    allowedContentTypes: [UTType.data],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        selectedFile = url
                        filePreviewItem = FilePreviewItem(previewItemURL: url)
                        showFileField.toggle()

                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                } // End of file picker

                Spacer(minLength: 0) // Float file upload and text buttons

                if showTextField {
                    Button(action: {
                        Task {
                            do {
                                let b = try await api.add_block(string: inputText)
                                if let lastPinnedIndex = blocks.lastIndex(where: { $0.pinned }) {
                                    blocks.insert(b, at: lastPinnedIndex + 1)
                                } else {
                                    blocks.insert(b, at: 0)
                                }
                                inputText = "" // Reset text field after adding text node
                            } catch {
                                alertMessage = "Error sending API request: \(error.localizedDescription)"
                                showingAlert = true
                            }
                        }
                    }) {
                        Text("send to space")
                            .font(.headline).fontWeight(.heavy).foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.orange)
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("We are brainfully sorry"),
                              message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                } // End if showTextField

                if showFileField {
                    Button(action: {
                        Task {
                            guard let url = selectedFile else {
                                throw APIError.invalidResponse
                            }

                            guard url.startAccessingSecurityScopedResource() else {
                                throw APIError.fileAccessDenied
                            }
                            defer { url.stopAccessingSecurityScopedResource() }

                            do {
                                let b = try await api.add_block(fileURL: url)
                                if let lastPinnedIndex = blocks.lastIndex(where: { $0.pinned }) {
                                    blocks.insert(b, at: lastPinnedIndex + 1)
                                } else {
                                    blocks.insert(b, at: 0)
                                }
                                print("File uploaded successfully.")

                                // Reset file picker and preview
                                selectedFile = nil
                                filePreviewItem = nil
                            } catch {
                                alertMessage = "Error sending API request: \(error.localizedDescription)"
                                showingAlert = true
                            }
                        }
                    }) {
                        Text("send file to space")
                            .font(.headline).fontWeight(.heavy).foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]),
                                                       startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("We are brainfully sorry"),
                              message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                } // End if showFileField

                Spacer(minLength: 0) // Float file upload and text buttons

                Button(action: { showTextField.toggle() }) {
                    HStack { Image(systemName: "pencil") }
                }
                .font(.headline).fontWeight(.heavy).foregroundColor(.white)
                .padding(.vertical, 15)
                .padding(.horizontal, 15)
                .buttonStyle(PlainButtonStyle())
                .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]),
                                           startPoint: .leading, endPoint: .trailing))
                .cornerRadius(30)

            } // End of HStack
            .padding(.horizontal)
            .onChange(of: selectedFile) { newValue in
                if let url = newValue {
                    filePreviewItem = FilePreviewItem(previewItemURL: url)
                } else {
                    filePreviewItem = nil
                }
            }
        }
    }
}
