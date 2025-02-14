import UIKit
import AVFoundation
import Vision


// Camera management class
class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var captureSession = AVCaptureSession() // Initializes session
    
    private var previewLayer: AVCaptureVideoPreviewLayer! // Displays camera feed
    
    private var objectDetectionLayer = CALayer() // Layer for drawing bounding boxes
    
    private var requests = [VNRequest]() // List of Vision requests from YOLO model
    
    // List of objects from audio transcription
    private var recognizedObjects: [String] = []
    
    private let maxTrackingRequests = 5
    private var trackingRequests = [VNTrackObjectRequest]()
    
    // Tracks camera position
    private var cameraPosition: AVCaptureDevice.Position = .back
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize camera & load YOLO model
        setCamera()
        setVision()
        
        // Listener for the startRecording() function
        NotificationCenter.default.addObserver(self, selector: #selector(updateRecognizedObjects(_:)), name: Notification.Name("RecognizedSpeech"), object: nil)
        
        // Listener for camera toggle
        NotificationCenter.default.addObserver(self, selector: #selector(cameraToggle(_:)), name: Notification.Name("switchCamera"), object: nil)
        
    }
    
    
    
    // Updates what objects to track based on voice recognition transcription
    @objc func updateRecognizedObjects(_ notification: Notification) {
        
        // If the audio transcription is not nil
        if let transcribedAudio = notification.object as? String {
            
            // Stores each word separately in a list
            recognizedObjects = transcribedAudio.split(separator: " ").map { $0.lowercased()}
            print("User wants to see: \(recognizedObjects)")
        }
        else {
            
            // Removes all tracking requests when voice recording stops
            recognizedObjects = []
            trackingRequests.removeAll()
        }
    }
    
    
    
    // Switches between front/back camera
    @objc func cameraToggle(_ notification: Notification) {
        
        if let isBackCamera = notification.object as? Bool {
            
            if isBackCamera {
                cameraPosition = .back
            }
            else {
                cameraPosition = .front
            }
        }
        
        setCamera() // Resets camera feed
    }
    
    

    // Initializes camera feed
    func setCamera() {
        
        // Resets capture session
        captureSession.stopRunning()
        captureSession = AVCaptureSession()
        
        captureSession.sessionPreset = .high // High camera quality
                
        // iPhone camera (front or back)
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            print("Error setting up camera input:", error)
        }
        
        // Base layer for camera feed
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        previewLayer.videoGravity = .resizeAspectFill // Fills screen
        previewLayer.frame = view.layer.bounds
        
        view.layer.addSublayer(previewLayer) // Add preview layer
        self.previewLayer = previewLayer

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        captureSession.addOutput(dataOutput)
        
        captureSession.startRunning()
        
        
        objectDetectionLayer.frame = view.layer.bounds
        view.layer.addSublayer(objectDetectionLayer) // Add bounding box layer
    }

    
    
    // Initializes YOLO model
    func setVision() {
        
        // Loads medium sized YOLO11 model in CoreML format
        guard let model = try? VNCoreMLModel(for: yolo11m().model) else {
            print("Failed to load YOLO11 model")
            return
        }
        
        // Initializes Vision framework request
        let request = VNCoreMLRequest(model: model, completionHandler: handleDetections)
        request.imageCropAndScaleOption = .scaleFill
        self.requests = [request]
    }
    
    
    
    
    // Captures every frame from camera
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Extracts image from video feed
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Preps image for analysis
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            // Runs YOLO detection inference on current frame
            try requestHandler.perform(self.requests)
            
            // Updates tracking on current frame
            self.updateTracking(pixelbuffer: pixelBuffer)
            
        } catch {
            print("Error performing request: \(error)")
        }
    }
    
    

    func handleDetections(request: VNRequest, error: Error?) {
        
        // Ensures detection layer is updated on the main thread
        DispatchQueue.main.async {
            
            self.objectDetectionLayer.sublayers?.removeAll() // Reset detection layer
            
            // Ensures we stay under the request limit
            if self.trackingRequests.count > self.maxTrackingRequests {
                self.trackingRequests.removeFirst(4)
            }
            

            // Safely extract detection objects
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    print("No objects detected")
                    return
                }
            
            // Debugging print statement
            if results.isEmpty {
                print("YOLO model is running but no objects detected")
            }
            else {
                print("Objects detected: \(results.count)")
            }
            
            // iterates thru each detected object in view
            for result in results {
                
                self.displayObjects(result: result)
                
            }
        }
    }
    
    
    func displayObjects(result: VNRecognizedObjectObservation) {
        
        // Debugging print statement
        print("Detected: \(result.labels.first?.identifier ?? "Unkown Object") with confidence \(result.confidence)")
        
        // Gets detected object label
        let foundLabel = result.labels.first?.identifier.lowercased() ?? "Unknown Object"
        
        // Checks if label is in audio transcription
        if self.recognizedObjects.contains(foundLabel) {
            
            // Gets device screen dimensions
            let screen: CGRect = UIScreen.main.bounds
            
            // Stores obect bounds as a CGRect instance
            let objectBounds = getObjectBounds(screen: screen, result: result)
            
            // If a tracking request is already tracking current object
            if let existingTracker = trackingRequests.first(where: {
                
                $0.inputObservation == result
            }) {
                // Reuse tracker
                existingTracker.inputObservation = result
            }
            else {
                // Create new tracker if we are under the limit
                if trackingRequests.count < maxTrackingRequests {
                    
                    let trackingRequest = VNTrackObjectRequest(detectedObjectObservation: result)
                    
                    trackingRequests.append(trackingRequest)
                }
            }
            
            
            // Displays bounding box on screen
            drawBoundingBox(frame: objectBounds, label: foundLabel)
        }
        
    }
    
    
    
    // Converts YOLO coordinates to iPhone screen coordinates
    func getObjectBounds(screen: CGRect, result: VNRecognizedObjectObservation) -> CGRect {
        
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        // Stores bounds for normalized coordinates
        let normalizedBounds = VNImageRectForNormalizedRect(result.boundingBox, Int(screenWidth), Int(screenHeight))
        
        // Converts normalized bounds to screen coordinates
        let x = normalizedBounds.minX
        let y = screenHeight - normalizedBounds.maxY
        let width = normalizedBounds.maxX - normalizedBounds.minX
        let height = normalizedBounds.maxY - normalizedBounds.minY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }

    

    // Displays bounding box on screen
    func drawBoundingBox(frame: CGRect, label: String) {
        
        // Layer for bounding box
        let boxLayer = CAShapeLayer()
        boxLayer.frame = frame
        boxLayer.borderColor = UIColor.red.cgColor
        boxLayer.borderWidth = 3

        // Layer for label text
        let textLayer = CATextLayer()
        textLayer.string = label
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.fontSize = 14
        // Sits on top of bounding box
        textLayer.frame = CGRect(x: frame.origin.x, y: frame.origin.y - 15, width: frame.width, height: 15)
        textLayer.alignmentMode = .center
        
        // Adds text & bounding box to object detection layer
        objectDetectionLayer.addSublayer(boxLayer)
        objectDetectionLayer.addSublayer(textLayer)
    }
    
    
    
    func updateTracking(pixelbuffer: CVPixelBuffer) {
        
        let requestHandler = VNSequenceRequestHandler() // Handles tracking requests
        
        do {
            
            try requestHandler.perform(trackingRequests, on: pixelbuffer)
            
        } catch {
            print("Tracking error: \(error)")
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(toggleBoundingBoxes(_:)), name: Notification.Name("ToggleBoundingBoxes"), object: nil)
        
    }
    
    

    // Shows/Hides the bounding boxes on screen
    @objc func toggleBoundingBoxes(_ notification: Notification) {
        if let isVisible = notification.object as? Bool {
            objectDetectionLayer.isHidden = !isVisible
        }
    }

}

