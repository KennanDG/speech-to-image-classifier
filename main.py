from ultralytics import YOLO
import coremltools as ct

sizes = ["n", "s", "m"]

for size in sizes:
    # Load YOLO model
    model = YOLO(f"yolo11{size}.pt")

    # Convert to CoreML
    model.export(format="coreml", int8=True, nms=True)


