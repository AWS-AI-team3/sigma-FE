#!/usr/bin/env python3
"""
Standalone hand tracking script for Flutter integration
"""

import sys
import os
import signal
import argparse

# Add the current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

try:
    # Set environment variables
    os.environ['OMP_NUM_THREADS'] = '1'
    
    from PyQt6.QtWidgets import QApplication
    from hand_overlay import HandOverlay
    from settings_client import SettingsClient
    
    def signal_handler(sig, frame):
        """Handle Ctrl+C gracefully"""
        print("\nStopping hand tracking...")
        app.quit()
    
    def main():
        global app
        
        # Parse command line arguments
        parser = argparse.ArgumentParser(description='Hand tracking with optional skeleton display')
        parser.add_argument('--show-skeleton', type=str, default='false', 
                          help='Show skeleton overlay (true/false)')
        parser.add_argument('--access-token', type=str, default='', 
                          help='Access token for server API requests')
        args = parser.parse_args()
        
        # Convert string to boolean
        show_skeleton = args.show_skeleton.lower() == 'true'
        print(f"Starting hand tracking with skeleton display: {show_skeleton}")
        
        # Load motion mapping from server if token is provided
        motion_mapping = None
        if args.access_token:
            print("Loading motion settings from server...")
            settings_client = SettingsClient()
            settings_client.set_access_token(args.access_token)
            settings_data = settings_client.get_motion_settings()
            if settings_data:
                motion_mapping = settings_client.parse_motion_mapping(settings_data)
                print(f"Loaded motion mapping: {motion_mapping}")
            else:
                print("Failed to load motion settings, using defaults")
        else:
            print("No access token provided, using default motion mapping")
        
        # Setup signal handler for graceful shutdown
        signal.signal(signal.SIGINT, signal_handler)
        
        # Create Qt application
        app = QApplication(sys.argv)
        
        # Create hand overlay with skeleton setting and motion mapping
        overlay = HandOverlay(show_skeleton=show_skeleton, motion_mapping=motion_mapping)
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