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
import pyautogui
import pyperclip
import time

from gesture_detector import GestureDetector
from cursor_controller import CursorController
from audio_recorder import AudioRecorder, WebSocketClient
from command_executor import CommandExecutor

class HandOverlay(QWidget):
    def __init__(self):
        super().__init__()
        print("HandOverlay initializing...")
        self.landmarks = None
        self.gesture = None
        
        # Setup window
        self.setup_window()
        
        # Initialize components
        self.gesture_detector = GestureDetector()
        self.cursor_controller = CursorController()
        
        # Initialize command executor
        self.command_executor = CommandExecutor()
        
        # Initialize audio recording with command callback
        print("Initializing WebSocket client...")
        self.websocket_client = WebSocketClient(
            transcript_callback=self.update_transcript,
            command_callback=self.handle_command_response
        )
        print("Initializing audio recorder...")
        self.audio_recorder = AudioRecorder(self.websocket_client)
        
        # Store current transcript for pasting
        self.current_transcript = ""
        self.last_transcript_time = None  # Track when we last received a transcript
        
        # Gesture tracking for reducing duplicate sends
        self.last_gesture_type = None
        self.gesture_send_counter = 0
        
        # Tracking state
        self.is_tracking = False
        
        # Camera with better settings and error handling
        self.cap = None
        self._init_camera()
        
    def _init_camera(self):
        """Initialize camera with error handling"""
        try:
            # Try DirectShow first (Windows)
            self.cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
            if not self.cap.isOpened():
                print("DirectShow backend failed, trying default backend")
                self.cap.release()
                # Fallback to default backend
                self.cap = cv2.VideoCapture(0)
            
            if self.cap.isOpened():
                self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
                self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Reduce buffer size
                print("Camera initialized successfully")
            else:
                print("Failed to initialize camera")
        except Exception as e:
            print(f"Error initializing camera: {e}")
            self.cap = None
        
        # Start tracking
        self.is_tracking = True
        
        # Timer for processing
        self.timer = QTimer()
        self.timer.timeout.connect(self.process_frame)
        self.timer.start(33)  # ~30 FPS
        
        # Timer for stdin processing - use thread instead of timer for Windows
        import threading
        self.stdin_thread = threading.Thread(target=self.stdin_monitor, daemon=True)
        self.stdin_thread.start()
        
        # Timer for WebSocket status check
        self.websocket_timer = QTimer()
        self.websocket_timer.timeout.connect(self.check_websocket_status)
        self.websocket_timer.start(5000)  # Check every 5 seconds
        
    def setup_window(self):
        """Setup transparent overlay window"""
        screen = QApplication.primaryScreen().geometry()
        self.setGeometry(0, 0, screen.width(), screen.height())
        
        self.setWindowFlags(
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.Tool |
            Qt.WindowType.WindowTransparentForInput |
            Qt.WindowType.WindowDoesNotAcceptFocus
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        self.setAttribute(Qt.WidgetAttribute.WA_ShowWithoutActivating)
        
    def process_frame(self):
        """Process camera frame"""
        if not self.is_tracking or not self.cap:
            return
            
        ret, frame = self.cap.read()
        if not ret:
            # Try to reinitialize camera if read fails
            print("Camera read failed, attempting to reinitialize...")
            if self.cap:
                self.cap.release()
            self._init_camera()
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
            
            # Handle audio recording based on gesture
            self.handle_audio_recording(gesture_data['gesture'])
            
            # Handle paste gesture
            self.handle_paste_gesture(gesture_data['gesture'])
            
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
            
            # Ensure UTF-8 encoding
            json_str = json.dumps(frame_data, ensure_ascii=False)
            print(json_str, flush=True)
        except Exception as e:
            # Don't print errors that could contain binary data
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
                # Ensure UTF-8 encoding
                json_str = json.dumps(gesture_data, ensure_ascii=False)
                print(json_str, flush=True)
                self.last_gesture_type = gesture
            
        except:
            pass
    
    def handle_audio_recording(self, gesture):
        """Handle audio recording based on gesture"""
        try:
            if gesture == "recording_start":
                # Start recording when thumb-ring pinch starts
                if not self.audio_recorder.is_recording:
                    # Check WebSocket connection before starting
                    print(f"WebSocket status before recording: {self.websocket_client.is_connected}")
                    if not self.websocket_client.is_connected:
                        print("WebSocket not connected - cannot start recording")
                        return
                    
                    success = self.audio_recorder.start_recording()
                    if success:
                        print("Audio recording started")
                        # Clear previous transcript when starting new recording
                        self.current_transcript = ""
                        self.last_transcript_time = None
                    else:
                        print("Failed to start audio recording")
            elif gesture == "recording_stop":
                # Stop recording when thumb-ring pinch ends
                if self.audio_recorder.is_recording:
                    self.audio_recorder.stop_recording()
                    print("Audio recording stopped")
                    # Start timer to clear transcript if no new transcript received
                    import time
                    self.last_transcript_time = time.time()
            # recording_hold - do nothing, keep recording
        except Exception as e:
            print(f"Error handling audio recording: {e}")
    
    def handle_paste_gesture(self, gesture):
        """Handle paste gesture for clipboard"""
        try:
            if gesture == "paste_start":
                # Simply paste whatever is currently in clipboard
                clipboard_content = pyperclip.paste()
                
                if clipboard_content.strip():
                    # Simulate Ctrl+V to paste at cursor position
                    try:
                        pyautogui.hotkey('ctrl', 'v')
                    except Exception as e:
                        print(f"Error simulating Ctrl+V: {e}")
                    
                    print(f"Pasted clipboard content: {clipboard_content}")
                    
                    # Send paste event to Flutter
                    paste_data = {
                        "type": "paste_action",
                        "text": clipboard_content
                    }
                    # Ensure UTF-8 encoding
                    json_str = json.dumps(paste_data, ensure_ascii=False)
                    print(json_str, flush=True)
                else:
                    print("No content available in clipboard to paste")
                
            # paste_hold and paste_end - do nothing
        except Exception as e:
            print(f"Error handling paste gesture: {e}")
    
    def update_transcript(self, text):
        """Update current transcript for pasting"""
        self.current_transcript = text
        
        # Automatically copy transcript to clipboard when received
        if text.strip():
            try:
                pyperclip.copy(text.strip())
                print(f"Transcript copied to clipboard: {text}")
            except Exception as e:
                print(f"Error copying transcript to clipboard: {e}")
        else:
            print(f"Transcript updated: {text}")
    
    def handle_command_response(self, data):
        """Handle command response from WebSocket"""
        try:
            if data.get('success'):
                command = data.get('command', '')
                if command:
                    print(f"명령어 수신: {command}")
                    # Execute the command
                    self.command_executor.execute_command(command)
            else:
                error_message = data.get('message', '명령어 생성 실패')
                print(f"명령어 생성 오류: {error_message}")
        except Exception as e:
            print(f"Error handling command response: {e}")
    
    def check_websocket_status(self):
        """Check WebSocket connection status"""
        if hasattr(self, 'websocket_client'):
            if self.websocket_client.is_connected:
                print("WebSocket Status: Connected")
            else:
                print("WebSocket Status: Disconnected - attempting reconnect")
                # Try to reconnect
                self.websocket_client._connect()
    
    def stdin_monitor(self):
        """Monitor stdin in separate thread"""
        import sys
        print("Stdin monitor started")
        print(f"Initial WebSocket status: {self.websocket_client.is_connected}")
        
        while self.is_tracking:
            try:
                line = sys.stdin.readline()
                if line:
                    line = line.strip()
                    if line:
                        print(f"Received stdin: {line}")
                        self.handle_flutter_command(line)
            except Exception as e:
                print(f"Error in stdin_monitor: {e}")
                break
    
    
    def handle_flutter_command(self, command_line):
        """Handle commands from Flutter"""
        try:
            data = json.loads(command_line)
            command_type = data.get('type', '')
            
            if command_type == 'send_command':
                # Send transcript text as command request
                text = data.get('text', self.current_transcript)
                print(f"Received send_command: '{text}'")
                
                if text.strip():
                    print(f"WebSocket connected: {self.websocket_client.is_connected}")
                    success = self.command_executor.send_command_request(self.websocket_client, text)
                    print(f"Command request sent: {success}")
                    
                    if not success:
                        # Send failure response to Flutter
                        failure_data = {
                            "type": "command_request",
                            "status": "failed",
                            "text": text
                        }
                        json_str = json.dumps(failure_data, ensure_ascii=False)
                        print(json_str, flush=True)
                else:
                    print("Empty text received")
            
            elif command_type == 'clear_transcript':
                # Clear current transcript
                self.current_transcript = ""
                self.last_transcript_time = None
                print("텍스트 초기화됨")
                
                # Send clear confirmation to Flutter
                clear_data = {
                    "type": "transcript_cleared"
                }
                json_str = json.dumps(clear_data, ensure_ascii=False)
                print(json_str, flush=True)
                
            elif command_type == 'manual_recording_start':
                # Manual recording start via mic button
                print("Manual recording start requested")
                self.handle_audio_recording("recording_start")
                
            elif command_type == 'manual_recording_stop':
                # Manual recording stop via mic button
                print("Manual recording stop requested")
                self.handle_audio_recording("recording_stop")
                
        except json.JSONDecodeError:
            pass
        except Exception as e:
            print(f"Error handling Flutter command: {e}")
    
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
        fingertip_indices = [8, 12, 16, 20]  # Index, middle, ring, and pinky fingertips
        
        for idx in fingertip_indices:
            if idx < len(self.landmarks):
                x = int(self.landmarks[idx][0] * screen_width)
                y = int(self.landmarks[idx][1] * screen_height)
                
                # Choose color based on gesture
                if (self.gesture and 
                    (self.gesture.startswith("left_click") or self.gesture == "left_click") and idx == 8):
                    color = QColor(0, 255, 0, 255)  # Green for left click
                elif (self.gesture and 
                      (self.gesture.startswith("right_click") or self.gesture == "right_click") and idx == 12):
                    color = QColor(255, 100, 0, 255)  # Orange for right click
                elif (self.gesture and 
                      (self.gesture.startswith("recording") or self.gesture in ["recording_start", "recording_hold"]) and idx == 16):
                    color = QColor(255, 255, 0, 255)  # Yellow for recording (ring finger)
                elif (self.gesture and 
                      (self.gesture.startswith("scroll") or self.gesture == "scroll_start" or self.gesture == "scroll_hold") and idx in [8, 12]):
                    color = QColor(255, 0, 255, 255)  # Magenta for scroll gestures (only index and middle)
                elif (self.gesture and 
                      (self.gesture.startswith("paste") or self.gesture in ["paste_start", "paste_hold"]) and idx == 20):
                    color = QColor(0, 255, 255, 255)  # Cyan for paste gesture (pinky finger)
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
        self.stdin_timer.stop()
        
        # Stop audio recording if active
        if hasattr(self, 'audio_recorder') and self.audio_recorder.is_recording:
            self.audio_recorder.stop_recording()
        
        # Close WebSocket connection
        if hasattr(self, 'websocket_client'):
            self.websocket_client.close()
        
        # Properly release camera with error handling
        if self.cap:
            try:
                self.cap.release()
                print("Camera released successfully")
            except Exception as e:
                print(f"Error releasing camera: {e}")
        
        # Additional camera cleanup for Windows
        import cv2
        cv2.destroyAllWindows()
        
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