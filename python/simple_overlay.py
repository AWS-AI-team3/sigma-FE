"""
Simple floating window overlay for hand skeleton
"""

import cv2
import numpy as np
import threading
import time
import sys
import base64
import json
from PyQt6.QtWidgets import QWidget, QApplication, QPushButton, QVBoxLayout, QHBoxLayout, QLabel
from PyQt6.QtCore import QTimer, Qt, pyqtSignal, QObject
from PyQt6.QtGui import QPainter, QPen, QColor, QFont, QPixmap, QImage
from typing import Optional, List
try:
    import pyautogui
except ImportError:
    print("WARNING: pyautogui not installed, mouse control will be disabled")
    pyautogui = None

from thumb_gesture_recognizer import ThumbGestureRecognizer


class HandOverlayWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.hand_landmarks = None
        self.gesture_data = None
        self.screen_width = QApplication.primaryScreen().size().width()
        self.screen_height = QApplication.primaryScreen().size().height()
        
        # Make widget transparent and always on top with highest priority
        self.setWindowFlags(
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.Tool |
            Qt.WindowType.WindowTransparentForInput |
            Qt.WindowType.WindowDoesNotAcceptFocus |
            Qt.WindowType.X11BypassWindowManagerHint
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        self.setAttribute(Qt.WidgetAttribute.WA_ShowWithoutActivating)
        
        # Set to full screen
        self.setGeometry(0, 0, self.screen_width, self.screen_height)
        
        # Timer to ensure it stays on top
        self.raise_timer = QTimer()
        self.raise_timer.timeout.connect(self.ensure_on_top)
        self.raise_timer.start(100)  # Check every 100ms
        
    def update_landmarks(self, landmarks: Optional[List[List[float]]], gesture_data: Optional[dict] = None):
        """Update hand landmarks and gesture data, trigger repaint"""
        self.hand_landmarks = landmarks
        self.gesture_data = gesture_data
        self.update()
        
    def ensure_on_top(self):
        """Ensure the overlay stays on top of all other windows"""
        if self.isVisible():
            self.raise_()
        
    def paintEvent(self, event):
        """Draw only index and middle fingers with color changes during interactions"""
        if not self.hand_landmarks:
            return
            
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Convert normalized landmarks to screen coordinates
        screen_landmarks = []
        for point in self.hand_landmarks:
            x = int(point[0] * self.screen_width)
            y = int(point[1] * self.screen_height)
            screen_landmarks.append((x, y))
        
        # Only draw index(8) and middle(12) finger tips
        finger_indices = [8, 12]  # Index, Middle fingertips
        
        # Default colors (grey)
        default_color = QColor(128, 128, 128, 200)  # Grey dots
        thumb_index_color = QColor(0, 255, 0, 255)  # Bright green for thumb-index interaction
        thumb_middle_color = QColor(255, 100, 0, 255)  # Orange for thumb-middle interaction
        
        # Check for thumb interactions
        is_thumb_index_interacting = False
        is_thumb_middle_interacting = False
        
        if self.gesture_data and self.gesture_data.get('type'):
            gesture_type = self.gesture_data['type']
            
            # Check for scroll gestures (both fingers should change color)
            if 'scroll' in gesture_type:
                is_thumb_index_interacting = True
                is_thumb_middle_interacting = True
            else:
                # Check for specific thumb-index interactions
                if any(keyword in gesture_type for keyword in ['thumb_index', 'drag', 'click']):
                    is_thumb_index_interacting = True
                # Check for thumb-middle interactions  
                if 'thumb_middle' in gesture_type:
                    is_thumb_middle_interacting = True
        
        # Draw finger dots with appropriate colors
        for i, finger_idx in enumerate(finger_indices):
            if finger_idx < len(screen_landmarks):
                x, y = screen_landmarks[finger_idx]
                
                # Choose color based on interaction
                if finger_idx == 8 and is_thumb_index_interacting:  # Index finger
                    color = thumb_index_color
                elif finger_idx == 12 and is_thumb_middle_interacting:  # Middle finger
                    color = thumb_middle_color
                else:
                    color = default_color
                
                # Draw the finger tip
                dot_pen = QPen(color)
                dot_pen.setWidth(10)  # Larger dots for visibility
                painter.setPen(dot_pen)
                painter.drawPoint(x, y)
    
    def draw_hand_connections(self, painter, landmarks):
        """Draw hand skeleton connections - now disabled for fingertips only mode"""
        # No connections drawn - only showing fingertips
        pass










class SimpleHandOverlay:
    def __init__(self):
        self.gesture_recognizer = ThumbGestureRecognizer()
        self.hand_overlay_widget = HandOverlayWidget()  # Full screen hand skeleton
        
        self.cap = None
        self.is_tracking = False
        self.camera_enabled = True  # Camera stream control
        
        # Callback for when tracking is stopped from remote
        self.tracking_stop_callback = None
        
        # Timer for updating
        self.timer = QTimer()
        self.timer.timeout.connect(self.process_frame)
        
        # Timer for checking stdin commands
        self.stdin_timer = QTimer()
        self.stdin_timer.timeout.connect(self.check_stdin_commands)
        self.stdin_timer.start(100)  # Check every 100ms
        
        # Initially hide overlay window
        self.hand_overlay_widget.hide()
        
    def start_tracking(self):
        """Start hand tracking"""
        if self.is_tracking:
            return
            
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        
        self.is_tracking = True
        
        # Show hand overlay
        self.hand_overlay_widget.show()
        
        self.timer.start(33)  # ~30 FPS
        
        print("Hand tracking started")
        
    def stop_tracking(self):
        """Stop hand tracking"""
        self.is_tracking = False
        self.timer.stop()
        
        if self.cap:
            self.cap.release()
            self.cap = None
            
        # Hide overlay window
        self.hand_overlay_widget.hide()
        
    def process_frame(self):
        """Process camera frame and update display"""
        if not self.is_tracking or not self.cap:
            return
            
        ret, frame = self.cap.read()
        if not ret:
            return
            
        # Flip frame horizontally for mirror effect
        frame = cv2.flip(frame, 1)
        
        # Send camera frame to Flutter (resize for performance)
        self.send_frame_to_flutter(frame)
        
        # Process frame with gesture recognizer
        processed_frame, gesture_data = self.gesture_recognizer.process_frame(frame)
        
        if gesture_data and gesture_data['landmarks'] is not None:
            # Update full screen overlay with landmarks and gesture data
            landmarks = gesture_data['landmarks'].tolist()
            self.hand_overlay_widget.update_landmarks(landmarks, gesture_data)
            
            # Move cursor to thumb position (always follow thumb)
            thumb_pos = self.gesture_recognizer.get_thumb_position(gesture_data['landmarks'])
            if thumb_pos and pyautogui:
                screen_x = int(thumb_pos[0] * pyautogui.size()[0])
                screen_y = int(thumb_pos[1] * pyautogui.size()[1])
                pyautogui.moveTo(screen_x, screen_y, duration=0.01)
            
            # Handle gestures for cursor control
            self.handle_gesture(gesture_data)
        else:
            # Clear overlay if no hand detected
            self.hand_overlay_widget.update_landmarks(None, None)
    
    def send_frame_to_flutter(self, frame):
        """Send camera frame to Flutter via stdout"""
        if not self.camera_enabled:
            return
            
        try:
            # Resize frame for better performance
            height, width = frame.shape[:2]
            new_width = 180
            new_height = int(height * (new_width / width))
            resized_frame = cv2.resize(frame, (new_width, new_height))
            
            # Encode frame as JPEG
            _, buffer = cv2.imencode('.jpg', resized_frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
            
            # Convert to base64 and send to stdout
            frame_b64 = base64.b64encode(buffer).decode('utf-8')
            frame_data = {
                "type": "camera_frame",
                "data": frame_b64
            }
            
            # Send JSON data to stdout for Flutter to read
            print(json.dumps(frame_data), flush=True)
            
        except Exception as e:
            # Don't print camera errors to avoid cluttering output
            pass
    
    def check_stdin_commands(self):
        """Check for commands from Flutter via stdin"""
        # For now, we'll use a simple file-based communication
        # This is more reliable across different platforms
        try:
            import os
            command_file = os.path.join(os.path.dirname(__file__), 'camera_command.txt')
            if os.path.exists(command_file):
                with open(command_file, 'r') as f:
                    command = f.read().strip()
                if command:
                    self.handle_flutter_command(command)
                # Remove the command file after processing
                os.remove(command_file)
        except Exception as e:
            pass  # Ignore file errors
    
    def handle_flutter_command(self, command):
        """Handle commands from Flutter"""
        if command == 'START_CAMERA':
            self.camera_enabled = True
            print(json.dumps({"type": "status", "message": "Camera enabled"}), flush=True)
        elif command == 'STOP_CAMERA':
            self.camera_enabled = False
            print(json.dumps({"type": "status", "message": "Camera disabled"}), flush=True)
            
    def handle_gesture(self, gesture_data):
        """Handle detected gestures"""
        gesture_type = gesture_data['type']
        landmarks = gesture_data['landmarks']
        
        if pyautogui is None:
            return
            
        # Handle scroll gestures
        if gesture_type.startswith("thumb_index_middle_scroll:"):
            scroll_speed = float(gesture_type.split(":")[1])
            self.handle_scroll(scroll_speed)
            return
        elif gesture_type in ["thumb_index_middle_scroll_start", "thumb_index_middle_scroll_hold"]:
            return  # No action needed
            
        # Handle click and drag gestures
        if gesture_type == "thumb_index_click":
            pyautogui.click()
            
        elif gesture_type == "thumb_index_double_click":
            pyautogui.doubleClick()
            
        elif gesture_type == "thumb_middle_pinch":
            pyautogui.rightClick()
            
        elif gesture_type == "thumb_index_pinch_start":
            pyautogui.mouseDown()
            
        elif gesture_type == "thumb_index_drag":
            pass  # Mouse position is already being updated
            
        elif gesture_type == "thumb_index_drag_end":
            pyautogui.mouseUp()
    
    def handle_scroll(self, scroll_speed: float):
        """Handle scroll gesture based on Y-axis movement"""
        if pyautogui is None:
            return
            
        # Convert scroll speed to scroll units
        # Positive scroll_speed = moved down = scroll down (negative units)
        # Negative scroll_speed = moved up = scroll up (positive units)
        scroll_units = int(-scroll_speed * 10 * 2)  # Sensitivity * 2
        
        # Apply scroll if above threshold
        if abs(scroll_units) >= 1:
            pyautogui.scroll(scroll_units)
            
    def set_tracking_stop_callback(self, callback):
        """Set callback function to be called when remote tracking stop is pressed"""
        self.tracking_stop_callback = callback
