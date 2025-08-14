"""
PyQt overlay to display hand landmarks
"""

import sys
import cv2
import json
import base64
from PyQt6.QtWidgets import QWidget, QApplication
from PyQt6.QtCore import QTimer, Qt
from PyQt6.QtGui import QPainter, QPen, QColor

from gesture_detector import GestureDetector
from cursor_controller import CursorController

class HandOverlay(QWidget):
    def __init__(self):
        super().__init__()
        self.landmarks = None
        self.gesture = None
        
        # Setup window
        self.setup_window()
        
        # Initialize components
        self.gesture_detector = GestureDetector()
        self.cursor_controller = CursorController()
        
        # Gesture tracking for reducing duplicate sends
        self.last_gesture_type = None
        self.gesture_send_counter = 0
        
        # Tracking state
        self.is_tracking = False
        
        # Camera
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        
        # Start tracking
        self.is_tracking = True
        
        # Timer for processing
        self.timer = QTimer()
        self.timer.timeout.connect(self.process_frame)
        self.timer.start(33)  # ~30 FPS
        
    def setup_window(self):
        """Setup transparent overlay window"""
        screen = QApplication.primaryScreen().geometry()
        self.setGeometry(0, 0, screen.width(), screen.height())
        
        self.setWindowFlags(
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.Tool |
            Qt.WindowType.WindowTransparentForInput
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        
    def process_frame(self):
        """Process camera frame"""
        if not self.is_tracking or not self.cap:
            return
            
        ret, frame = self.cap.read()
        if not ret:
            return
            
        # Flip frame for mirror effect
        frame = cv2.flip(frame, 1)
        
        # Send frame to Flutter
        self.send_frame_to_flutter(frame)
        
        # Detect gestures
        processed_frame, gesture_data = self.gesture_detector.process_frame(frame)
        
        if gesture_data and gesture_data['landmarks'] is not None:
            # Update landmarks and gesture data
            landmarks = gesture_data['landmarks'].tolist()
            self.landmarks = landmarks
            self.gesture = gesture_data['gesture']
            
            # Update cursor position
            if gesture_data['thumb_pos'] is not None:
                self.cursor_controller.update_cursor(gesture_data['thumb_pos'])
            
            # Handle gestures
            self.cursor_controller.handle_gesture(gesture_data['gesture'])
            
            # Send gesture to Flutter
            self.send_gesture_to_flutter(gesture_data['gesture'])
            
            # Update display
            self.update()
        else:
            # Clear overlay if no hand detected
            self.landmarks = None
            self.gesture = None
            self.update()
    
    def send_frame_to_flutter(self, frame):
        """Send camera frame to Flutter"""
        try:
            # Resize and encode
            height, width = frame.shape[:2]
            new_width = 180
            new_height = int(height * (new_width / width))
            resized_frame = cv2.resize(frame, (new_width, new_height))
            
            _, buffer = cv2.imencode('.jpg', resized_frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
            frame_b64 = base64.b64encode(buffer).decode('utf-8')
            
            frame_data = {
                "type": "camera_frame",
                "data": frame_b64
            }
            
            print(json.dumps(frame_data), flush=True)
        except:
            pass
    
    def send_gesture_to_flutter(self, gesture):
        """Send gesture to Flutter - only when gesture changes"""
        try:
            # Only send if gesture changed or every 10 frames for fist/open_hand
            should_send = False
            if gesture != self.last_gesture_type:
                should_send = True
                self.gesture_send_counter = 0
            elif gesture in ['fist', 'open_hand']:
                # Send fist/open_hand every 10 frames to ensure Flutter receives it
                self.gesture_send_counter += 1
                if self.gesture_send_counter >= 10:
                    should_send = True
                    self.gesture_send_counter = 0
            
            if should_send:
                gesture_data = {
                    "type": "gesture",
                    "gesture_type": gesture,
                    "confidence": 0.8
                }
                print(json.dumps(gesture_data))
                self.last_gesture_type = gesture
            
        except:
            pass
    
    def paintEvent(self, event):
        """Draw hand landmarks"""
        if not self.landmarks:
            return
            
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Convert normalized coordinates to screen coordinates
        screen_width = self.width()
        screen_height = self.height()
        
        # Draw fingertips
        fingertip_indices = [8, 12]  # Index and middle fingertips
        
        for idx in fingertip_indices:
            if idx < len(self.landmarks):
                x = int(self.landmarks[idx][0] * screen_width)
                y = int(self.landmarks[idx][1] * screen_height)
                
                # Choose color based on gesture
                if self.gesture == "left_click" and idx == 8:
                    color = QColor(0, 255, 0, 255)  # Green for left click
                elif self.gesture == "right_click" and idx == 12:
                    color = QColor(255, 100, 0, 255)  # Orange for right click
                elif self.gesture == "scroll":
                    color = QColor(255, 0, 255, 255)  # Magenta for scroll
                else:
                    color = QColor(128, 128, 128, 200)  # Gray default
                
                pen = QPen(color)
                pen.setWidth(10)
                painter.setPen(pen)
                painter.drawPoint(x, y)
    
    def closeEvent(self, event):
        """Clean up on close"""
        self.is_tracking = False
        self.timer.stop()
        if self.cap:
            self.cap.release()
        self.gesture_detector.cleanup()
        event.accept()

def main():
    app = QApplication(sys.argv)
    overlay = HandOverlay()
    overlay.show()
    
    try:
        sys.exit(app.exec())
    except KeyboardInterrupt:
        print("Shutting down...")
        overlay.close()

if __name__ == "__main__":
    main()