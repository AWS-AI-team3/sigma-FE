"""
Command execution module for COMMANDIFY functionality
"""

import subprocess
import json
import sys

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
                'action': 'commandify', 
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