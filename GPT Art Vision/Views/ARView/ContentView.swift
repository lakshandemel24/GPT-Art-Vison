import SwiftUI
import UIKit

struct ContentView: View {
    @State private var showPaintingView = false

    var body: some View {
        ZStack {
            
            if !showPaintingView {
                CustomARViewRepresentable(showPaintingView: $showPaintingView)
                    .ignoresSafeArea()
            }
            
            if showPaintingView {
                PaintingView(showPaintingView: $showPaintingView)
            }
        }
    }

    
}
