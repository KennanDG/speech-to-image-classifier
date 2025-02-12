
import SwiftUI

struct ContentView: View {
    
    // Determines whether bounding boxes will be displayed on screen
    @State private var showBoundingBoxes = true
    
    var body: some View {
        
        // Stacks views on top of each other
        ZStack {
            // Borderless camera view
            CameraView()
                .edgesIgnoringSafeArea(.all)
            
            // Arranges views vertically
            VStack {
                Spacer() // Pushes button to bottom of screen
                
                // Shows/Hides bounding boxes
                Button(action: {
                    showBoundingBoxes.toggle()
                    NotificationCenter.default.post(name: Notification.Name("ToggleBoundingBoxes"), object: showBoundingBoxes)
                }) {
                    
                    Text(showBoundingBoxes ? "Hide Boxes" : "Show Boxes")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
