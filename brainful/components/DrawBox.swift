import SwiftUI
import PencilKit
import UIKit

struct DrawBoxViewController: UIViewControllerRepresentable {
    @ObservedObject var drawingState: DrawingState // Add a @ObservedObject property to hold the drawing state

    func makeUIViewController(context: Context) -> DrawBox {
        return DrawBox(drawingState: drawingState) // Pass the DrawingState object to the DrawBox view controller
    }
    func updateUIViewController(_ uiViewController: DrawBox, context: Context) {
        // Not needed for this example
    }
}

class DrawBox: UIViewController {
    private let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        // canvas.drawingPolicy = .anyInput  Only Apple Pencil
        return canvas
    }()
    var drawingState: DrawingState
    let drawing = PKDrawing()
    var toolPicker: PKToolPicker?
    
    init(drawingState: DrawingState) { // Add a constructor that takes a DrawingState object as a parameter
            self.drawingState = drawingState
            super.init(nibName: nil, bundle: nil)
        }
    
    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    override func viewDidLoad() {
        super.viewDidLoad()

        canvasView.delegate = self
        DispatchQueue.main.async { // Update drawing state on the main thread, outside of the view update cycle
            self.canvasView.drawing = self.drawingState.drawing
        }
        view.addSubview(canvasView)

        // Set up the tool picker
        toolPicker = PKToolPicker()
        toolPicker?.setVisible(true, forFirstResponder: canvasView)
        toolPicker?.addObserver(canvasView)
    }


    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            canvasView.frame = view.bounds
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            canvasView.becomeFirstResponder()
        }

        deinit {
            toolPicker?.removeObserver(canvasView)
        }
    }

    extension DrawBox: PKCanvasViewDelegate {
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawingState.drawing = canvasView.drawing // Update the drawing state whenever the drawing changes
        }
    }

    class DrawingState: ObservableObject {
        @Published var drawing = PKDrawing() // Create a @Published property to hold the drawing state
        var isCanvasEmpty: Bool {
            return drawing.strokes.isEmpty
        }
}
