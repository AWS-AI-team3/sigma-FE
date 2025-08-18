"""
Simple gesture detection using MediaPipe
"""

import cv2
import mediapipe as mp
import numpy as np
import sys
from typing import Optional, Dict

class GestureDetector:
    def __init__(self, motion_mapping=None):
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        
        # Thresholds
        self.pinch_threshold = 0.06
        self.scroll_threshold = 0.08  # Larger threshold for scroll
        
        # Motion mapping configuration
        self.motion_mapping = motion_mapping or {
            'left_click': 'M1',      # Default: 엄지+검지 핀치
            'right_click': 'M2',     # Default: 엄지+중지 핀치  
            'paste': 'M3',           # Default: 엄지+새끼 핀치
        }
        
        # Scroll state tracking
        self.is_scrolling = False
        self.scroll_start_pos = None
        
        # Recording state tracking
        self.is_recording = False
        
        # Click state tracking
        self.is_left_clicking = False
        self.is_right_clicking = False
        
        # Paste state tracking
        self.is_pasting = False
        
    def process_frame(self, frame):
        """Process frame and detect gestures"""
        try:
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = self.hands.process(rgb_frame)
            
            gesture_data = None
            
            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    gesture_data = self._extract_gesture(hand_landmarks)
                    break  # Only process first hand
                    
            return frame, gesture_data
        except:
            return frame, None
    
    def _extract_gesture(self, landmarks):
        """Extract gesture data from hand landmarks"""
        # Get landmark positions
        positions = []
        for lm in landmarks.landmark:
            positions.append([lm.x, lm.y, lm.z])
        
        positions = np.array(positions)
        
        # Detect gesture
        gesture_type = self._classify_gesture(positions)
        
        return {
            'landmarks': positions,
            'gesture': gesture_type,
            'thumb_pos': positions[4] if len(positions) > 4 else None
        }
    
    def _classify_gesture(self, positions):
        """Classify gesture based on landmarks and motion mapping configuration"""
        # Landmark indices
        THUMB_TIP = 4
        THUMB_IP = 3
        INDEX_TIP = 8
        INDEX_PIP = 6
        MIDDLE_TIP = 12
        MIDDLE_PIP = 10
        RING_TIP = 16
        RING_PIP = 14
        PINKY_TIP = 20
        PINKY_PIP = 18
        
        # Get key positions
        thumb_tip = positions[THUMB_TIP]
        index_tip = positions[INDEX_TIP]
        middle_tip = positions[MIDDLE_TIP]
        ring_tip = positions[RING_TIP]
        pinky_tip = positions[PINKY_TIP]
        
        # Calculate distances for all possible pinch gestures
        thumb_index_distance = np.sqrt(np.sum((thumb_tip - index_tip) ** 2))
        thumb_middle_distance = np.sqrt(np.sum((thumb_tip - middle_tip) ** 2))
        thumb_ring_distance = np.sqrt(np.sum((thumb_tip - ring_tip) ** 2))
        thumb_pinky_distance = np.sqrt(np.sum((thumb_tip - pinky_tip) ** 2))
        
        # Map motion codes to gesture distances and types
        gesture_distances = {
            'M1': ('thumb_index', thumb_index_distance),
            'M2': ('thumb_middle', thumb_middle_distance), 
            'M3': ('thumb_pinky', thumb_pinky_distance),
        }
        
        # Determine which gestures are active based on motion mapping
        left_click_motion = self.motion_mapping.get('left_click', 'M1')
        right_click_motion = self.motion_mapping.get('right_click', 'M2')
        paste_motion = self.motion_mapping.get('paste', 'M3')
        
        # Get distances for configured gestures
        left_click_gesture, left_click_distance = gesture_distances.get(left_click_motion, ('thumb_index', thumb_index_distance))
        right_click_gesture, right_click_distance = gesture_distances.get(right_click_motion, ('thumb_middle', thumb_middle_distance))
        paste_gesture, paste_distance = gesture_distances.get(paste_motion, ('thumb_pinky', thumb_pinky_distance))
        
        # Check active gestures
        is_left_click_gesture = left_click_distance < self.pinch_threshold
        is_right_click_gesture = right_click_distance < self.pinch_threshold
        is_paste_gesture = paste_distance < self.pinch_threshold
        
        # Fixed recording gesture (always thumb-ring for now)
        is_recording_gesture = thumb_ring_distance < self.pinch_threshold
        
        
        # Handle recording state but continue processing other gestures
        recording_gesture = None
        if is_recording_gesture:
            # Reset scroll state when making thumb-ring pinch
            if self.is_scrolling:
                self.is_scrolling = False
                self.scroll_start_pos = None
            
            if not self.is_recording:
                # First time making thumb-ring pinch - start recording
                self.is_recording = True
                recording_gesture = "recording_start"
            else:
                # Continue holding thumb-ring pinch - keep recording
                recording_gesture = "recording_hold"
        else:
            # Not making thumb-ring pinch
            if self.is_recording:
                # Just stopped thumb-ring pinch - stop recording
                self.is_recording = False
                recording_gesture = "recording_stop"
        
        # Handle paste gesture
        paste_gesture_result = None
        if is_paste_gesture:
            # Reset scroll state when making paste pinch
            if self.is_scrolling:
                self.is_scrolling = False
                self.scroll_start_pos = None
            
            if not self.is_pasting:
                # First time making paste pinch - trigger paste
                self.is_pasting = True
                paste_gesture_result = "paste_start"
            else:
                # Continue holding paste pinch
                paste_gesture_result = "paste_hold"
        else:
            # Not making paste pinch
            if self.is_pasting:
                # Just stopped paste pinch
                self.is_pasting = False
                paste_gesture_result = "paste_end"
        
        # Check for 3-finger scroll (when thumb, index, and middle are close together)
        if (thumb_index_distance < self.scroll_threshold and 
            thumb_middle_distance < self.scroll_threshold):
            return self._handle_scroll(positions)
        
        # Reset scroll state if not in triple pinch
        if self.is_scrolling:
            self.is_scrolling = False
            self.scroll_start_pos = None
        
        # Return paste gesture first if active (highest priority)
        if paste_gesture_result:
            return paste_gesture_result
            
        # Return recording gesture if active (second priority)
        if recording_gesture:
            return recording_gesture
        
        # Check for left click gesture with hold state
        if is_left_click_gesture:
            if not self.is_left_clicking:
                self.is_left_clicking = True
                return "left_click_start"
            else:
                return "left_click_hold"
        else:
            if self.is_left_clicking:
                self.is_left_clicking = False
                return "left_click_end"
        
        # Check for right click gesture with hold state
        if is_right_click_gesture:
            if not self.is_right_clicking:
                self.is_right_clicking = True
                return "right_click_start"
            else:
                return "right_click_hold"
        else:
            if self.is_right_clicking:
                self.is_right_clicking = False
                return "right_click_end"
        
        # Default cursor control
        return "cursor"
    
    def _handle_scroll(self, positions):
        """Handle 3-finger scroll gesture based on Y-axis movement"""
        THUMB_TIP = 4
        INDEX_TIP = 8
        MIDDLE_TIP = 12
        
        # Get current triple pinch center position (average of 3 fingertips)
        thumb_pos = positions[THUMB_TIP]
        index_pos = positions[INDEX_TIP]
        middle_pos = positions[MIDDLE_TIP]
        current_pinch_pos = (thumb_pos + index_pos + middle_pos) / 3
        
        if not self.is_scrolling:
            # First time detecting triple pinch - initialize scroll tracking
            self.scroll_start_pos = current_pinch_pos
            self.is_scrolling = True
            return "scroll_start"
        else:
            # Calculate Y-axis movement from initial pinch position
            y_displacement = current_pinch_pos[1] - self.scroll_start_pos[1]
            
            # Calculate scroll speed based on Y displacement
            # Negative y_displacement = moved up = scroll up
            # Positive y_displacement = moved down = scroll down
            scroll_speed = y_displacement * 30
            
            # Apply minimum threshold to avoid micro-scrolls
            if abs(scroll_speed) > 0.4:
                return f"scroll:{scroll_speed}"
            else:
                return "scroll_hold"
    
    def update_motion_mapping(self, motion_mapping: Dict[str, str]):
        """Update motion mapping configuration"""
        self.motion_mapping = motion_mapping
        print(f"Updated motion mapping: {motion_mapping}")
    
    def cleanup(self):
        """Clean up resources"""
        if self.hands:
            self.hands.close()