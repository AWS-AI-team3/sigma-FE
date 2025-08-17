"""
Command execution module for COMMANDIFY functionality
"""

import subprocess
import json
import sys
import platform
import os
from pathlib import Path

class CommandExecutor:
    def __init__(self):
        pass
    
    def execute_command(self, command):
        """Execute system command and return result"""
        try:
            print(f"실행 중: {command}")
            
            # Send execution status to Flutter
            exec_data = {
                "type": "command_execution",
                "status": "executing",
                "command": command
            }
            json_str = json.dumps(exec_data, ensure_ascii=False)
            print(json_str, flush=True)
            
            # Execute command with timeout
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True, 
                timeout=30,
                encoding='cp949'
            )
            
            if result.returncode == 0:
                output = result.stdout.strip()
                if output:
                    print("명령어 실행 완료")
                    
                    # Send success status to Flutter
                    success_data = {
                        "type": "command_execution",
                        "status": "success",
                        "command": command,
                        "output": output,
                        "copied": False
                    }
                    json_str = json.dumps(success_data, ensure_ascii=False)
                    print(json_str, flush=True)
                    
                    return True, output, False  # success, output, not copied
                else:
                    print("명령어 실행 완료")
                    
                    # Send success status to Flutter
                    success_data = {
                        "type": "command_execution",
                        "status": "success",
                        "command": command,
                        "output": "",
                        "copied": False
                    }
                    json_str = json.dumps(success_data, ensure_ascii=False)
                    print(json_str, flush=True)
                    
                    return True, "", False  # success, no output, not copied
            else:
                error_output = result.stderr.strip() if result.stderr else "알 수 없는 오류"
                print(f"실행 오류: {error_output}")
                
                # Send error status to Flutter
                error_data = {
                    "type": "command_execution",
                    "status": "error",
                    "command": command,
                    "error": error_output
                }
                json_str = json.dumps(error_data, ensure_ascii=False)
                print(json_str, flush=True)
                
                return False, error_output, False  # failed, error, not copied
                
        except subprocess.TimeoutExpired:
            error_msg = "명령어 실행 시간 초과"
            print(error_msg)
            
            # Send timeout status to Flutter
            timeout_data = {
                "type": "command_execution",
                "status": "timeout",
                "command": command
            }
            json_str = json.dumps(timeout_data, ensure_ascii=False)
            print(json_str, flush=True)
            
            return False, error_msg, False
            
        except Exception as e:
            error_msg = f"실행 실패: {str(e)}"
            print(error_msg)
            
            # Send failure status to Flutter
            failure_data = {
                "type": "command_execution",
                "status": "failed",
                "command": command,
                "error": str(e)
            }
            json_str = json.dumps(failure_data, ensure_ascii=False)
            print(json_str, flush=True)
            
            return False, error_msg, False
    
    def send_command_request(self, websocket_client, text):
        """Send command request to WebSocket server"""
        try:
            if not text.strip():
                print("텍스트 없음")
                return False
                
            command_message = {
                'action': 'generate_command', 
                'type': 'request_command', 
                'request': text.strip()
            }
            
            success = websocket_client.send_message(command_message)
            if success:
                print("명령어 변환 중...")
                
                # Send request status to Flutter
                request_data = {
                    "type": "command_request",
                    "status": "sent",
                    "text": text.strip()
                }
                json_str = json.dumps(request_data, ensure_ascii=False)
                print(json_str, flush=True)
                
                return True
            else:
                print("명령어 변환 실패")
                return False
                
        except Exception as e:
            print(f"명령어 요청 실패: {str(e)}")
            return False


class LocalAgent:
    """Local system information provider and command executor for Windows"""
    
    def __init__(self):
        pass

    def get_os_type(self):
        """Get OS type - updated to properly identify Windows"""
        system = platform.system().lower()
        if system == 'windows':
            return 'windows'
        elif system == 'darwin':
            return 'macos'
        elif system == 'linux':
            return 'linux'
        else:
            return 'unknown'

    def get_recent_files(self):
        """Get recent files for Windows system"""
        try:
            if self.get_os_type() != 'windows':
                return "Windows만 지원됩니다."

            # Windows에서 최근 파일 검색
            recent_files = []
            
            # 일반적인 사용자 폴더들에서 최근 파일 검색
            search_paths = [
                Path.home() / "Desktop",
                Path.home() / "Documents", 
                Path.home() / "Downloads"
            ]
            
            # 확장자별로 검색
            extensions = ['.txt', '.doc', '.docx', '.pdf', '.xlsx', '.xls', 
                         '.ppt', '.pptx', '.jpg', '.png', '.mp4', '.mp3']
            
            for search_path in search_paths:
                if search_path.exists():
                    for ext in extensions:
                        try:
                            # 각 확장자별로 파일 검색
                            pattern = f"*{ext}"
                            files = list(search_path.glob(pattern))
                            
                            # 최근 수정된 파일부터 정렬
                            files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
                            
                            # 상위 몇개만 추가
                            for file in files[:2]:  # 각 확장자당 최대 2개
                                if len(recent_files) < 10:  # 전체 최대 10개
                                    recent_files.append(str(file))
                        except Exception:
                            continue
            
            if recent_files:
                return '\n'.join(recent_files[:10])
            else:
                return "최근 파일을 찾을 수 없습니다."
                
        except Exception as e:
            return f"파일 검색 오류: {str(e)}"

    def execute_command(self, command):
        """Execute system command and return result"""
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True, 
                timeout=30,
                encoding='utf-8'
            )
            return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
        except subprocess.TimeoutExpired:
            return False, "", "실행 시간 초과"
        except Exception as e:
            return False, "", str(e)