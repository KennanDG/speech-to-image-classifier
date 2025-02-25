
import Foundation
import Speech
import AVFoundation
import UIKit


class VoiceRecognition: ObservableObject {
    
    @Published var isRecording = false
    @Published var recognizedWords: String?
    @Published var detectedObjects: [String]?
    
    private let speechRecognizer = SFSpeechRecognizer() // Speech recognition model
    
    private let audioEngine = AVAudioEngine() // Manages audio input
    
    // Buffer for speech recognizer requests
    private let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    // Stores speech recognition session
    private var recognitionTask: SFSpeechRecognitionTask?
    
    
    // Labels for model's trained dataset
    private var cocoDataset: [String:Int] = [
        "person": 0,
        "bicycle": 1,
        "car": 2,
        "motorcycle": 3,
        "airplane": 4,
        "bus": 5,
        "train": 6,
        "truck": 7,
        "boat": 8,
        "traffic light": 9,
        "fire hydrant": 10,
        "stop sign": 11,
        "parking meter": 12,
        "bench": 13,
        "bird": 14,
        "cat": 15,
        "dog": 16,
        "horse": 17,
        "sheep": 18,
        "cow":19,
        "elephant": 20,
        "bear": 21,
        "zebra": 22,
        "giraffe": 23,
        "backpack": 24,
        "umbrella": 25,
        "handbag": 26,
        "tie": 27,
        "suitcase": 28,
        "frisbee": 29,
        "skis": 30,
        "snowboard": 31,
        "sports ball": 32,
        "kite": 33,
        "baseball bat": 34,
        "baseball glove": 35,
        "skateboard": 36,
        "surfboard": 37,
        "tennis racket": 38,
        "bottle": 39,
        "wine glass": 40,
        "cup": 41,
        "fork": 42,
        "knife": 43,
        "spoon": 44,
        "bowl": 45,
        "banana": 46,
        "apple": 47,
        "sandwich": 48,
        "orange": 49,
        "broccoli": 50,
        "carrot": 51,
        "hot dog": 52,
        "pizza": 53,
        "donut": 54,
        "cake": 55,
        "chair": 56,
        "couch": 57,
        "potted plant": 58,
        "bed": 59,
        "dining table": 60,
        "toilet": 61,
        "tv": 62,
        "laptop": 63,
        "mouse": 64,
        "remote": 65,
        "keyboard": 66,
        "cell phone": 67,
        "microwave": 68,
        "oven": 69,
        "toaster": 70,
        "sink": 71,
        "refrigerator": 72,
        "book": 73,
        "clock": 74,
        "vase": 75,
        "scissors": 76,
        "teddy bear": 77,
        "hair dryer": 78,
        "toothbrush": 79,
    ]
    
    
    
    
    
    init() {
        requestSpeechAuthorization()
    }
    
    func getDetectedObjects() -> [String] {
        
        guard let objects = detectedObjects
        else {
            return []
        }
        
        return objects
    }
    
    // Checks for user permission for speech recognition
    func requestSpeechAuthorization() {
        
        SFSpeechRecognizer.requestAuthorization { status in
            
            if status != .authorized {
                print("Speech recognition is not authorized")
            }
            
        }
    }
    
    // Turns voice recording on or off
    func toggleVoiceRecognition() {
        
        if isRecording {
            stopRecording()
        }
        else {
            startRecording()
        }
        
        let hapticFeedback = UIImpactFeedbackGenerator(style: .heavy)
        hapticFeedback.prepare()
        hapticFeedback.impactOccurred()
    }
    
    
    func startRecording() {
        
        isRecording = true
        
        let inputNode = audioEngine.inputNode // Accesses the device microphone
        
        let recordingFormat = inputNode.outputFormat(forBus: 0) // Audio format
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat)
        {buffer, _ in
            
            self.recognitionRequest.append(buffer) // Adds buffer to request
        }
        
        audioEngine.prepare()
        try? audioEngine.start() // Begins recording
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            
            // If the recorded speech returns a transcription
            if let result {
                
                self.detectedObjects = []
                
                // Debugging print statement
                print("Audio transcription: \(result.bestTranscription.formattedString)")
                
                self.recognizedWords = result.bestTranscription.formattedString.lowercased()
                
                if self.recognizedWords != nil {
                    // Stores each word separately in a list
                    let words = self.recognizedWords!.split(separator: " ").map { $0.lowercased()}
                    
                    
                    for word in words {
                        if self.cocoDataset.keys.contains(word) {
                            self.detectedObjects?.append(word)
                        }
                    }
                }
                
                // Debugging print statement
                print("VoiceRecognition detected objects: \(self.detectedObjects ?? [])\n")
                
                // Sends notification to CameraViewController
                NotificationCenter.default.post(name: Notification.Name("RecognizedSpeech"), object: self.detectedObjects)
            }
            else if let error {
                print("Speech Recognition error: \(error.localizedDescription)")
                self.stopRecording()
            }
        }
        
        
    }
    
    
    func stopRecording() {
        
        isRecording = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizedWords = nil
        detectedObjects = nil
        
        
        // Sends notification to CameraViewController
        NotificationCenter.default.post(name: Notification.Name("RecognizedSpeech"), object: self.recognizedWords)
    }
    
    
    
}
