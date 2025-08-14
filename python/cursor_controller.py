"""
Mouse cursor control using detected gestures
"""

import pyautogui
import time

class CursorController:
    def __init__(self):
        self.screen_width, self.screen_height = pyautogui.size()
        self.last_click_time = 0
        self.click_cooldown = 0.3  # Prevent multiple clicks
        
        # Disable pyautogui failsafe
        pyautogui.FAILSAFE = False
        
    def update_cursor(self, thumb_pos):
        """Update cursor position based on thumb position"""
        if thumb_pos is not None:
            screen_x = int(thumb_pos[0] * self.screen_width)
            screen_y = int(thumb_pos[1] * self.screen_height)
            pyautogui.moveTo(screen_x, screen_y, duration=0.01)
    
    def handle_gesture(self, gesture):
        """Handle detected gestures"""
        try:
            current_time = time.time()
            
            # Check cooldown
            if current_time - self.last_click_time < self.click_cooldown:
                return
            
            if gesture == "left_click":
                pyautogui.click()
                self.last_click_time = current_time
                
            elif gesture == "right_click":
                pyautogui.rightClick()
                self.last_click_time = current_time
                
            elif gesture == "scroll":
                # For now, just skip - scroll implementation can be added later
                pass
                
        except:
            pass