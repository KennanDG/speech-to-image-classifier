
import SwiftUI

struct ContentView: View {
    
    // Initializes voice recognition class as an observable object
    @StateObject private var voiceRecognition = VoiceRecognition()
    
    @State private var showBoundingBoxes: Bool = true // Shows/Hides bounding boxes
    
    // Toggles between front & back camera
    @State private var isBackCamera: Bool = true
    
    @State private var showInfo: Bool = false
    
    @State private var selectedObjectsToHide: [String] = []
    
    
    // Button Background colors
    private var redBox = Color.red.opacity(0.7)
    private var blueBox = Color.blue.opacity(0.7)
    private var whiteBox = Color.white.opacity(0.7)
    private var blackBox = Color.black.opacity(0.7)

    var body: some View {
        
        
        // Stacks views on top of each other
        ZStack {
            CameraView()
                .edgesIgnoringSafeArea(.all) // Borderless view

            VStack {
                
                HStack {
                    Spacer() // Pushes info button to top-right corner
                    
                    Button(action: {
                        showInfo.toggle()
                    }) {
                        // Generic info icon
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                    }
                }
                
                Spacer() // Pushes buttons to bottom of screen
                
                HStack {
                    
                    Button(action: {
                        isBackCamera.toggle()
                        NotificationCenter.default.post(name: Notification.Name("switchCamera"), object: isBackCamera)
                    }) {
                        // Icon to flip camera front/back
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    }
                    
                    // Starts/Stops voice recording
                    Button(action: {
                        voiceRecognition.toggleVoiceRecognition()
                    }) {
                        Text(voiceRecognition.isRecording ? "Stop" : "Record")
                            .padding()
                            .background(voiceRecognition.isRecording ? redBox : blueBox)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    
                    // Displays object labels based on user verbal command
                    Menu {
                        ForEach(voiceRecognition.detectedObjects ?? ["None"], id: \.self) { object in
                            Button(action: {
                                toggleObjectSelection(object)
                            }) {
                                VStack {
                                    Text(object)
                                    if selectedObjectsToHide.contains(object) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        
                    } label: {
                        Text("Hide")
                            .padding()
                            .background(blackBox)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    // Sends notification to CameraViewController
                    .onChange(of: selectedObjectsToHide) { oldSelection, newSelection in
                        NotificationCenter.default.post(name: Notification.Name("BoxesToHide"), object: newSelection)
                    }

//                    // Show/Hide bounding boxes
//                    Button(action: {
//                        showBoundingBoxes.toggle()
//                        NotificationCenter.default.post(name: Notification.Name("BoxesToHide"), object: voiceRecognition.detectedObjects)
//                    }) {
//                        Text(showBoundingBoxes ? "Hide" : "Show")
//                            .padding()
//                            .background(showBoundingBoxes ? blackBox : whiteBox)
//                            .foregroundColor(showBoundingBoxes ? .white : .black)
//                            .cornerRadius(10)
//                    }
                }
                .padding(.bottom, 20)
            }
        }
        // Displays general info about the app
        .alert("Speech-to-Image-Classifier", isPresented: $showInfo, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text("This app allows you to detect & track objects in real-time using voice commands. Tap 'Record' to start speaking, and the app will highlight detected objects of your choosing. Tap 'Hide/Show' to toggle bounding box visibility. And click the camera icon to flip between the front & back cameras.")
        })
        
    }
    
    // Adds/Rmoves object to hidden bounding box list
    private func toggleObjectSelection(_ object: String) {
        if selectedObjectsToHide.contains(object) {
            selectedObjectsToHide.removeAll { $0 == object }
        } else {
            selectedObjectsToHide.append(object)
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
