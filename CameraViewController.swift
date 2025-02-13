import UIKit
import AVFoundation
import Vision


// Camera management class
class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession = AVCaptureSession() // Initializes session
    
    var previewLayer: AVCaptureVideoPreviewLayer! // Displays camera feed
    
    var objectDetectionLayer = CALayer() // Layer for drawing bounding boxes
    
    var requests = [VNRequest]() // List of Vision requests from YOLO model
    
    var recognizedObjects: [String] = [] // List of objects from audio transcription
    
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
    
    
    @objc func updateRecognizedObjects(_ notification: Notification) {
        
        if let transcribedAudio = notification.object as? String {
            recognizedObjects = transcribedAudio.split(separator: " ").map { $0.lowercased()}
            print("User wants to see: \(recognizedObjects)")
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

    func setVision() {
        
        // Loads medium sized YOLO11 model
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
            // Runs YOLO inference on current frame
            try requestHandler.perform(self.requests)
        } catch {
            print("Error performing request: \(error)")
        }
    }

    func handleDetections(request: VNRequest, error: Error?) {
        
        // Ensures detection layer is updated on the main thread
        DispatchQueue.main.async {
            
            self.objectDetectionLayer.sublayers?.removeAll() // Reset detection layer

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
                
                // Debugging print statement
                print("Detected: \(result.labels.first?.identifier ?? "Unkown Object") with confidence \(result.confidence)")
                
                // Gets detected object label
                let foundLabel = result.labels.first?.identifier.lowercased() ?? "Unknown Object"
                
                // Checks if label is in audio transcription
                if self.recognizedObjects.contains(foundLabel) {
                    
                    // Gets device screen dimensions
                    let screenRect: CGRect = UIScreen.main.bounds
                    let screenWidth = screenRect.size.width
                    let screenHeight = screenRect.size.height
                    
                    // Stores bounds for normalized coordinates
                    let normalizedBounds = VNImageRectForNormalizedRect(result.boundingBox, Int(screenWidth), Int(screenHeight))
                    
                    // Converts normalized bounds to screen coordinates
                    let x = normalizedBounds.minX
                    let y = screenHeight - normalizedBounds.maxY
                    let width = normalizedBounds.maxX - normalizedBounds.minX
                    let height = normalizedBounds.maxY - normalizedBounds.minY
                    
                    // Stores obect bounds as a CGRect instance
                    let objectBounds = CGRect(x: x, y: y, width: width, height: height)
                    
                    // let transformedBox = self.transformBoundingBox(objectBounds)
                    
                    // Displays bounding box on screen
                    self.drawBoundingBox(frame: objectBounds, label: foundLabel)
                }
            }
        }
    }

    // Converts YOLO coordinates to IOS screen coordinates
    func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        
        let width = boundingBox.width * view.frame.width
        let height = boundingBox.height * view.frame.height
        let x = boundingBox.minX * view.frame.width
        let y = (1 - boundingBox.maxY) * view.frame.height // Flip vertically

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

