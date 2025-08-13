#!/usr/bin/env python3
"""
Standalone hand tracking script for Flutter integration
Starts the SimpleHandOverlay directly when called from Flutter
"""

import sys
import os

# Add the current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

try:
    import os
    # Set environment variables to help with DLL loading
    os.environ['OMP_NUM_THREADS'] = '1'
    
    from PyQt6.QtWidgets import QApplication
    import signal
    
    # Import from current directory instead of src module
    from simple_overlay import SimpleHandOverlay
    
    def signal_handler(sig, frame):
        """Handle Ctrl+C gracefully"""
        print("\nStopping hand tracking...")
        app.quit()
    
    def main():
        # Setup signal handler for graceful shutdown
        signal.signal(signal.SIGINT, signal_handler)
        
        # Create Qt application
        app = QApplication(sys.argv)
        
        # Create and start hand overlay
        overlay = SimpleHandOverlay()
        overlay.start_tracking()
        
        print("Hand tracking overlay started. Press Ctrl+C to stop.")
        
        # Run the application
        try:
            sys.exit(app.exec())
        except KeyboardInterrupt:
            print("\nShutting down...")
            overlay.stop_tracking()
    
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