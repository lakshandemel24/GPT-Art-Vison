import SwiftUI

struct CustomARViewRepresentable: UIViewRepresentable {
    
    @Binding var showPaintingView: Bool
    
    func makeUIView(context: Context) -> CustomARView {
        let arView = CustomARView(frame: UIScreen.main.bounds)
        arView.showPaintingView = $showPaintingView
        return arView
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) { }
}
