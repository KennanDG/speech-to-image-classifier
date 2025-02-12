
import Foundation
import Speech
import AVFoundation


class VoiceRecognition: ObservableObject {
    
    @Published var isRecording = false
    @Published var recognizedText: String?
    
    private let speechRecognizer = SFSpeechRecognizer() // Speech recognition model
    
    private let audioEngine = AVAudioEngine() // Manages audio input
    
    // Buffer for speech recognizer requests
    private let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    // Stores speech recognition session
    private var recognitionTask: SFSpeechRecognitionTask?
    
    
    init() {
        requestSpeechAuthorization()
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
                
                // Debugging print statement
                print("Audio transcription: \(result.bestTranscription.formattedString)")
                
                self.recognizedText = result.bestTranscription.formattedString.lowercased()
                
                // Sends notification to CameraViewController
                NotificationCenter.default.post(name: Notification.Name("RecognizedSpeech"), object: self.recognizedText)
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
    }
    
    
    
}
