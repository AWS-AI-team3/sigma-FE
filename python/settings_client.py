"""
Settings client for communicating with the server API
"""

import requests
import json
import os
from typing import Dict, Optional

class SettingsClient:
    def __init__(self):
        self.base_url = "https://www.3-sigma-server.com"
        self.api_version = "/v1"
        self.access_token = None
        
    def set_access_token(self, token: str):
        """Set access token for API requests"""
        self.access_token = token
    
    def get_motion_settings(self) -> Optional[Dict]:
        """Get motion settings from server"""
        try:
            if not self.access_token:
                print("No access token available")
                return None
                
            url = f"{self.base_url}{self.api_version}/settings/motion"
            headers = {
                'accept': '*/*',
                'Authorization': f'Bearer {self.access_token}',
            }
            
            response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('sucess') == True:
                    print("Motion settings loaded from server")
                    return data.get('data', {})
                else:
                    print(f"Failed to load motion settings: {data.get('error', 'Unknown error')}")
                    return None
            else:
                print(f"HTTP error {response.status_code} while loading motion settings")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"Network error while loading motion settings: {e}")
            return None
        except Exception as e:
            print(f"Error loading motion settings: {e}")
            return None
    
    def parse_motion_mapping(self, settings_data: Dict) -> Dict[str, str]:
        """
        Parse motion settings and create gesture mapping
        Returns mapping from gesture types to motion codes
        """
        if not settings_data:
            # Default mapping if no settings available
            return {
                'left_click': 'M1',      # 엄지+검지 핀치
                'right_click': 'M2',     # 엄지+중지 핀치  
                'paste': 'M3',           # 엄지+새끼 핀치
            }
        
        # Extract motion codes from server response
        motion_left_click = settings_data.get('motionLeftClick', 'M1')
        motion_right_click = settings_data.get('motionRightClick', 'M2')
        motion_wheel_scroll = settings_data.get('motionWheelScroll', 'M3')  # Used for paste
        
        print(f"Motion mapping - Left: {motion_left_click}, Right: {motion_right_click}, Paste: {motion_wheel_scroll}")
        
        return {
            'left_click': motion_left_click,
            'right_click': motion_right_click,
            'paste': motion_wheel_scroll,
        }
    
    def load_token_from_flutter_storage(self) -> bool:
        """
        Try to load access token from Flutter's storage locations
        This is a fallback method when token is not passed directly
        """
        # Common Flutter storage locations (may vary by platform)
        possible_paths = [
            os.path.expanduser("~/.flutter_secure_storage"),
            os.path.expanduser("~/AppData/Local/sigma_flutter_ui"),
            os.path.expanduser("~/Documents/sigma_flutter_ui"),
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                try:
                    # Try to read token files
                    for file in os.listdir(path):
                        if 'access_token' in file.lower():
                            with open(os.path.join(path, file), 'r') as f:
                                token = f.read().strip()
                                if token:
                                    self.access_token = token
                                    print(f"Loaded access token from {path}")
                                    return True
                except Exception as e:
                    continue
        
        print("Could not load access token from Flutter storage")
        return False