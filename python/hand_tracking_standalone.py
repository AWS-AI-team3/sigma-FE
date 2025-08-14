#!/usr/bin/env python3
"""
Standalone hand tracking script for Flutter integration
"""

import sys
import os
import signal

# Add the current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

try:
    # Set environment variables
    os.environ['OMP_NUM_THREADS'] = '1'
    
    from PyQt6.QtWidgets import QApplication
    from hand_overlay import HandOverlay
    
    def signal_handler(sig, frame):
        """Handle Ctrl+C gracefully"""
        print("\nStopping hand tracking...")
        app.quit()
    
    def main():
        global app
        
        # Setup signal handler for graceful shutdown
        signal.signal(signal.SIGINT, signal_handler)
        
        # Create Qt application
        app = QApplication(sys.argv)
        
        # Create hand overlay
        overlay = HandOverlay()
        overlay.show()
        
        print("Hand tracking started. Press Ctrl+C to stop.")
        
        # Run the application
        try:
            sys.exit(app.exec())
        except KeyboardInterrupt:
            print("\nShutting down...")
            overlay.close()
    
    if __name__ == "__main__":
        main()
        
except ImportError as e:
    print(f"Import error: {e}")
    print("Please ensure PyQt6, OpenCV, and MediaPipe are installed:")
    print("pip install PyQt6 opencv-python mediapipe pyautogui")
    sys.exit(1)
except Exception as e:
    print(f"Error starting hand tracking: {e}")
    sys.exit(1)