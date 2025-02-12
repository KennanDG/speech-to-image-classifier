import UIKit
import AVFoundation
import Vision


// Camera management class
class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession = AVCaptureSession() // Initializes session
    
    var previewLayer: AVCaptureVideoPreviewLayer! // Displays camera feed
    
    var objectDetectionLayer = CALayer() // Layer for drawing bounding boxes
    
    var requests = [VNRequest]() // List of Vision requests from YOLO model

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize camera & load YOLO model
        setCamera()
        setVision()
    }

    func setCamera() {
        
        captureSession.sessionPreset = .high // High camera quality
        
        // iPhone camera
        guard let camera = AVCaptureDevice.default(for: .video) else { return }
        
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
                
                // YOLO returns normalized coordinates (0-1)
                let boundingBox = result.boundingBox
                
                // Converts YOLO coordinates to screen coordinates
                let transformedBox = self.transformBoundingBox(boundingBox)
                
                // Displays bounding box on screen
                self.drawBoundingBox(frame: transformedBox, label: result.labels.first?.identifier ?? "Unknown")
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

