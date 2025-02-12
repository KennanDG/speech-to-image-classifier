
import SwiftUI

struct ContentView: View {
    
    // Initializes voice recognition class
    @StateObject private var voiceRecognition = VoiceRecognition()
    
    @State private var showBoundingBoxes = true // Shows/Hides bounding boxes

    var body: some View {
        
        // Stacks views on top of each other
        ZStack {
            CameraView()
                .edgesIgnoringSafeArea(.all) // Borderless view

            VStack {
                Spacer() // Pushes button to bottom of screen
                
                HStack {
                    
                    // Starts/Stops voice recording
                    Button(action: {
                        voiceRecognition.toggleVoiceRecognition()
                    }) {
                        Text(voiceRecognition.isRecording ? "Stop Listening" : "Start Listening")
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    // Show/Hide bounding boxes
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
