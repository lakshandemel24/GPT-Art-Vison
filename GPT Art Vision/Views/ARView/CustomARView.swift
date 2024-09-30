import ARKit
import RealityKit
import SwiftUI

// Global variable to store the current painting name with the artist
var currentPainting: String = ""
// Global variable to store the current painting name
var painting: String = ""

class CustomARView: ARView, ARSessionDelegate {
    
    private var lastSeenAnchors = [UUID: Date]()
    var showPaintingView: Binding<Bool>?

    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        setupARSession()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupARSession() {
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        // Load the reference images from the asset catalog
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            print("Failed to load AR reference images.")
            return
        }
        
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = referenceImages.count
        
        // Set the session delegate
        self.session.delegate = self
        
        // Run the session
        self.session.run(configuration)
    }

    // ARSessionDelegate method
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let imageAnchor = anchor as? ARImageAnchor else { continue }
            
            DispatchQueue.main.async {
                let frameEntity = self.createFrameEntity(for: imageAnchor)
                
                // Install gestures on the text entity
                if let textModel = frameEntity.children.first as? HasCollision {
                    self.installGestures([.rotation, .scale], for: textModel)
                }
                
                self.scene.addAnchor(frameEntity)
                
                let imageName = imageAnchor.referenceImage.name ?? "Unknown image"
                var textString = imageName
                
                switch imageName {
                case "La Gioconda":
                    textString = "La Gioconda di Leonardo Da Vinci"
                    SpeechManager.shared.speak(text: "Questo di fronte a te, è la Gioconda di Leonardo da Vinci, realizzato tra il 1503 e il 1506.") {
                        self.showPaintingView?.wrappedValue = true
                    }
                case "Il Bacio":
                    textString = "Il bacio di Francesco Hayez"
                    SpeechManager.shared.speak(text: "Questo di fronte a te, è Il Bacio di Francesco Hayez, realizzato nel 1859.") {
                        self.showPaintingView?.wrappedValue = true
                    }
                default:
                    textString = "Dipinto in lavorazione..."
                    SpeechManager.shared.speak(text: "Questo dipinto è ancora in corso di analisi, riprova in futuro") {
                        
                    }
                }
                
                LoggingSystem.push(eventLog: ["event" : "Painting detected", "paintingName" : textString], verbose: false)
                
                currentPainting = textString
                painting = imageName
            }
            break
        }
    }
    
    private func createFrameEntity(for imageAnchor: ARImageAnchor) -> AnchorEntity {
        let width = Float(imageAnchor.referenceImage.physicalSize.width)
        
        // Create a parent anchor entity
        let anchorEntity = AnchorEntity(anchor: imageAnchor)
        
        // Create a text entity with a name based on the image detected
        let textString = imageAnchor.referenceImage.name ?? "Unknown image"
        
        // Font with increased extrusion depth for a pronounced 3D appearance
        let textMesh = MeshResource.generateText(
            textString,
            extrusionDepth: 0.05, // Increased extrusion depth for clearer 3D effect
            font: .systemFont(ofSize: 0.1, weight: .bold),
            containerFrame: CGRect.zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        // Detailed material with white color and minimal roughness for clarity
        let textMaterial = SimpleMaterial(
            color: .cyan, // Set color to white
            roughness: 0.1, // Lower roughness for a smoother surface
            isMetallic: false // Non-metallic appearance to avoid a grayish look
        )
        
        let textModel = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // Rotate the text to be upright
        textModel.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3(1, 0, 0))
        
        // Scale the text entity to fit within the image width
        let maxTextWidth = width * 0.8
        let textBoundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = textBoundingBox.extents.x
        let scaleFactor = maxTextWidth / textWidth
        textModel.scale = SIMD3(repeating: scaleFactor)
        
        // Position the text entity directly above the image, centered and attached
        textModel.position = SIMD3(
            x: -width / 2.5,
            y: 0.01,
            z: -0.127
        )
        
        // Add a collision component to enable gestures
        textModel.generateCollisionShapes(recursive: true)
        
        // Add the text entity to the anchor
        anchorEntity.addChild(textModel)
        
        return anchorEntity
    }



}
