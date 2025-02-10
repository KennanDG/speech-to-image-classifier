

import SwiftUI


struct FrameView: View {
    var image: CGImage?
    private let label = Text("FrameView")
    
    var body: some View {
        if let image = image {
            Image(image, scale: 1.0, orientation: .up, label: label)
        }
        else {
            Color.green
        }
    }
}

struct FrameView_Previews: PreviewProvider {
    static var previews: some View {
        FrameView()
    }
}
