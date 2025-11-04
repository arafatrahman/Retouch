import SwiftUI
import UIKit

// This wraps a UIKit view for drawing
struct DrawingCanvasView: UIViewRepresentable {
    
    @Binding var paths: [CGPath]
    @Binding var brushSize: CGFloat
    @Binding var isDrawing: Bool
    
    var onUndo: () -> Void // Callback for undo

    func makeUIView(context: Context) -> CanvasUIView {
        let view = CanvasUIView()
        view.delegate = context.coordinator
        view.brushSize = brushSize
        view.isUserInteractionEnabled = true
        return view
    }

    func updateUIView(_ uiView: CanvasUIView, context: Context) {
        uiView.brushSize = brushSize
        // Tell the view to re-draw its paths
        uiView.paths = paths
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // The Coordinator handles messages from the UIKit view
    class Coordinator: NSObject, CanvasUIViewDelegate {
        var parent: DrawingCanvasView

        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }

        func didStartDrawing() {
            parent.isDrawing = true
        }

        func didAddNewPath(_ path: CGPath) {
            parent.paths.append(path)
        }
        
        func didFinishDrawing() {
            parent.isDrawing = false
        }
    }
}

// Delegate protocol
protocol CanvasUIViewDelegate: AnyObject {
    func didStartDrawing()
    func didAddNewPath(_ path: CGPath)
    func didFinishDrawing()
}

// The actual UIKit view that handles touches
class CanvasUIView: UIView {
    
    weak var delegate: CanvasUIViewDelegate?
    
    var brushSize: CGFloat = 30.0
    private var currentPath: UIBezierPath?
    
    // This draws all the completed paths
    var paths: [CGPath] = [] {
        didSet {
            setNeedsDisplay() // Redraw
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // This is called when the view needs to draw
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        context?.setLineCap(.round)
        context?.setLineJoin(.round)
        
        // Draw all the *finished* paths
        for path in paths {
            context?.setLineWidth(brushSize)
            context?.addPath(path)
            context?.strokePath()
        }
        
        // Draw the *current* path being drawn
        if let currentPath = currentPath {
            context?.setLineWidth(brushSize)
            context?.addPath(currentPath.cgPath)
            context?.strokePath()
        }
    }

    // --- Touch Handlers ---
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        delegate?.didStartDrawing()
        currentPath = UIBezierPath()
        currentPath?.lineWidth = brushSize
        currentPath?.lineCapStyle = .round
        currentPath?.lineJoinStyle = .round
        currentPath?.move(to: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let currentPath = currentPath else { return }
        currentPath.addLine(to: touch.location(in: self))
        setNeedsDisplay() // Redraw
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let path = currentPath?.cgPath {
            delegate?.didAddNewPath(path)
        }
        currentPath = nil
        delegate?.didFinishDrawing()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentPath = nil
        delegate?.didFinishDrawing()
    }
}
