"""
Simple gesture detection using MediaPipe
"""

import cv2
import mediapipe as mp
import numpy as np
from typing import Optional, Dict

class GestureDetector:
    def __init__(self):
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        
        # Thresholds
        self.pinch_threshold = 0.05
        
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
        """Classify gesture based on landmarks"""
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
        
        # Calculate distances
        thumb_index_distance = np.sqrt(np.sum((thumb_tip - index_tip) ** 2))
        thumb_middle_distance = np.sqrt(np.sum((thumb_tip - middle_tip) ** 2))
        
        # Check for pinch gestures
        if thumb_index_distance < self.pinch_threshold:
            return "left_click"
        if thumb_middle_distance < self.pinch_threshold:
            return "right_click"
        
        # Count extended fingers
        fingers_up = 0
        finger_tips = [THUMB_TIP, INDEX_TIP, MIDDLE_TIP, RING_TIP, PINKY_TIP]
        finger_pips = [THUMB_IP, INDEX_PIP, MIDDLE_PIP, RING_PIP, PINKY_PIP]
        
        for i in range(5):
            tip_y = float(positions[finger_tips[i]][1])
            pip_y = float(positions[finger_pips[i]][1])
            if tip_y < pip_y:
                fingers_up += 1
        
        # Gesture classification
        if fingers_up <= 1:
            return "fist"
        elif fingers_up >= 4:
            return "open_hand"
        else:
            return "cursor"
    
    def cleanup(self):
        """Clean up resources"""
        if self.hands:
            self.hands.close()