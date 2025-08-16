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
        
        # Disable pyautogui failsafe and pause
        pyautogui.FAILSAFE = False
        pyautogui.PAUSE = 0
        
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
            
            # Handle new click hold states
            if gesture == "left_click_start":
                pyautogui.mouseDown()
                self.last_click_time = current_time
            elif gesture == "left_click_hold":
                # Continue holding - no action needed
                pass
            elif gesture == "left_click_end":
                pyautogui.mouseUp()
                self.last_click_time = current_time
                
            elif gesture == "right_click_start":
                pyautogui.mouseDown(button='right')
                self.last_click_time = current_time
            elif gesture == "right_click_hold":
                # Continue holding - no action needed
                pass
            elif gesture == "right_click_end":
                pyautogui.mouseUp(button='right')
                self.last_click_time = current_time
                
            # Legacy gesture support (fallback)
            elif gesture == "left_click":
                if current_time - self.last_click_time >= self.click_cooldown:
                    pyautogui.click()
                    self.last_click_time = current_time
            elif gesture == "right_click":
                if current_time - self.last_click_time >= self.click_cooldown:
                    pyautogui.rightClick()
                    self.last_click_time = current_time
                
            elif gesture == "scroll_start":
                # Just started scrolling - no action needed
                pass
            elif gesture == "scroll_hold":
                # Holding scroll position - no action needed
                pass
            elif gesture.startswith("scroll:"):
                # Dynamic scroll based on Y movement
                scroll_speed = float(gesture.split(":")[1])
                scroll_units = int(-scroll_speed * 20)  # Convert to scroll units, invert direction
                if abs(scroll_units) >= 1:
                    pyautogui.scroll(scroll_units)
                
        except:
            pass