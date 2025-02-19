from ultralytics import YOLO
import coremltools as ct


# Load YOLO model
model = YOLO(f"yolo11m.pt")

# Convert to CoreML
model.export(format="coreml", int8=True, nms=True, imgsz=1280)


