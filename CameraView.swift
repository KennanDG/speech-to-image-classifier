
import SwiftUI
import AVFoundation


// SwiftUI wrapper for a UIKit camera controller
struct CameraView: UIViewControllerRepresentable {
    
    // Initializes camera view controller
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        return viewController
    }
    
    // Required for SwiftUI but is not used
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
}
