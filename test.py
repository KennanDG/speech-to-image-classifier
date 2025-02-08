from faster_whisper import WhisperModel
from ultralytics import YOLO
import cv2
import nltk


def find_key_by_value(dictionary: dict, known_value):
    for key, value in dictionary.items():
        if value == known_value:
            return key


# Load Faster Whisper model
whisper = WhisperModel(model_size_or_path='base', compute_type='float32')

yolo = YOLO('yolo11n.pt')

names = yolo.names

camera = cv2.VideoCapture(0)

segments, _ = whisper.transcribe('./Recording.m4a')

class_index:int

found_class:bool

for segment in segments:
    words = nltk.tokenize.word_tokenize(segment.text)
    for word in words:
        if word in names.values():
            class_index = find_key_by_value(names, word)
            found_class = True
            break
        else:
            found_class = False


while camera.isOpened():
    ret, frame = camera.read()
    if not ret:
        break


    results = yolo(frame, show=True, stream=True, show_boxes=False)
    results = list(results)

    class_index:int

    found_class:bool

    for segment in segments:
        words = segment.text.split()
        for word in words:
            if word in names.values():
                class_index = find_key_by_value(names, word)
                found_class = True
            else:
                found_class = False
        


    if found_class:
        for i, result in enumerate(results):
            for box in result.boxes:
                if box.cls == class_index:
                    x1, y1, x2, y2 = map(int, box.xyxy[0])  # Get box coordinates
                    class_name = names[int(box.cls)]


                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    cv2.putText(frame, class_name, (x1, y1 - 10),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
    
    
    cv2.imshow("YOLO Camera Feed", frame)



camera.release()
cv2.destroyAllWindows()





