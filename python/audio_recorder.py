"""
Audio recording module for gesture-based voice recognition
"""

import sys
import queue
import threading
import json
import base64
import numpy as np
import sounddevice as sd
import websocket
from command_executor import LocalAgent

class AudioRecorder:
    def __init__(self, websocket_client):
        self.websocket_client = websocket_client
        self.is_recording = False
        self.audio_queue = queue.Queue()

    def audio_callback(self, audio_data, frames, time, status):
        """Audio callback for sounddevice"""
        if self.is_recording:
            # Scale and convert to int16 (same as main.py)
            scaled_audio = (audio_data * 32767).astype(np.int16)
            self.audio_queue.put(scaled_audio.tobytes())

    def start_recording(self):
        """Start audio recording"""
        if self.is_recording:
            return False
            
        self.is_recording = True
        
        # Send start transcribe message
        self.websocket_client.send_message({
            'action': 'transcribe_streaming', 
            'type': 'start_transcribe'
        })
        
        try:
            # Start audio input stream with optimized settings for speech recognition
            self.stream = sd.InputStream(
                samplerate=16000,
                channels=1,
                dtype='float32',
                blocksize=1024,  # Increased chunk size for better word recognition
                callback=self.audio_callback,
                latency='low',  # Request low latency from audio system
            )
            self.stream.start()
            
            # Start audio processing thread
            self.processing_thread = threading.Thread(target=self._process_audio, daemon=True)
            self.processing_thread.start()
            
            return True
        except Exception as e:
            print(f"Error starting audio recording: {e}")
            self.is_recording = False
            return False

    def _process_audio(self):
        """Process audio data in separate thread"""
        while self.is_recording:
            try:
                # Get audio data with reasonable timeout for better speech recognition
                audio_data = self.audio_queue.get(timeout=0.1)  # Increased timeout for better word formation
                
                # Encode and send with timestamp for latency tracking
                import time
                encoded_audio = base64.b64encode(audio_data).decode('utf-8')
                self.websocket_client.send_message({
                    'action': 'transcribe_streaming',
                    'type': 'send_audio',
                    'data': encoded_audio,
                    'timestamp': time.time()  # Add timestamp for latency tracking
                })
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Error processing audio: {e}")
                break

    def stop_recording(self):
        """Stop audio recording"""
        if not self.is_recording:
            return
            
        self.is_recording = False
        
        try:
            # Stop and close stream first
            if hasattr(self, 'stream'):
                self.stream.stop()
                self.stream.close()
                delattr(self, 'stream')  # Remove stream attribute
                
            # Wait for processing thread to finish
            if hasattr(self, 'processing_thread'):
                self.processing_thread.join(timeout=1.0)
                delattr(self, 'processing_thread')  # Remove thread attribute
                
            # Clear audio queue to prevent leftover data
            while not self.audio_queue.empty():
                try:
                    self.audio_queue.get_nowait()
                except:
                    break
                    
            print("Audio recording cleanup completed")
                
        except Exception as e:
            print(f"Error stopping audio recording: {e}")
        
        # Send stop transcribe message
        self.websocket_client.send_message({
            'action': 'transcribe_streaming', 
            'type': 'stop_transcribe'
        })


class WebSocketClient:
    """WebSocket client for audio transcription and command execution"""
    
    WEBSOCKET_URL = "wss://4tj4nr6tca.execute-api.ap-northeast-2.amazonaws.com/dev/"
    
    # Action constants
    ACTION_TRANSCRIBE_STREAMING = 'transcribe_streaming'
    ACTION_GENERATE_COMMAND = 'generate_command'
    
    # Type constants
    TYPE_START_TRANSCRIBE = 'start_transcribe'
    TYPE_STOP_TRANSCRIBE = 'stop_transcribe'
    TYPE_SEND_AUDIO = 'send_audio'
    TYPE_REQUEST_COMMAND = 'request_command'
    TYPE_RESPOND_COMMAND = 'respond_command'
    TYPE_REQUEST_INFO = 'request_info'
    TYPE_RESPOND_INFO = 'respond_info'
    TYPE_TRANSCRIPT = 'transcript'
    
    # Info constants
    INFO_OS = 'get_os'
    INFO_RECENT_FILES = 'get_recent_files'

    def __init__(self, transcript_callback=None, command_callback=None, local_agent=None, info_request_callback=None):
        self.websocket_connection = None
        self.is_connected = False
        self.audio_streaming = False
        self.transcript_callback = transcript_callback
        self.command_callback = command_callback
        self.local_agent = local_agent
        self.info_request_callback = info_request_callback
        self._connect()

    def _connect(self):
        """Connect to WebSocket server"""
        try:
            self.websocket_connection = websocket.WebSocketApp(
                self.WEBSOCKET_URL,
                on_message=self._on_message,
                on_open=self._on_open,
                on_close=self._on_close,
                on_error=self._on_error,
            )
            # Start WebSocket in background thread
            threading.Thread(target=self.websocket_connection.run_forever, daemon=True).start()
        except Exception as e:
            print(f"WebSocket connection error: {e}")

    def _on_open(self, ws):
        """WebSocket opened"""
        self.is_connected = True
        self.audio_streaming = False
        self._audio_logged = False
        print("WebSocket connected")

    def _on_close(self, ws, code, msg):
        """WebSocket closed"""
        self.is_connected = False
        self.audio_streaming = False
        self._audio_logged = False
        print("WebSocket disconnected")

    def _on_error(self, ws, error):
        """WebSocket error"""
        print(f"WebSocket error: {error}")

    def _on_message(self, ws, message):
        """Handle WebSocket message"""
        try:
            data = json.loads(message)
            if data.get('type') == 'transcript':
                text = data.get('text', '')
                is_partial = data.get('is_partial', False)
                
                # Calculate and log response latency
                import time
                current_time = time.time()
                print(f"Transcript received at {current_time}: '{text}', is_partial: {is_partial}")
                
                # Call callback to update transcript in hand_overlay
                # Show both partial and final results for real-time subtitles
                if self.transcript_callback and text.strip():
                    self.transcript_callback(text, is_partial)
                
                # Transcript is now handled by hand_overlay.py to avoid duplication
            
            # COMMANDIFY response handling
            elif data.get('type') == 'respond_command':
                if self.command_callback:
                    self.command_callback(data)
                    
                # Send command response to Flutter
                command_data = {
                    "type": "command_response",
                    "success": data.get('success', False),
                    "command": data.get('command', ''),
                    "message": data.get('message', '')
                }
                try:
                    json_str = json.dumps(command_data, ensure_ascii=False)
                    if json_str and json_str.strip():
                        print(json_str, flush=True)
                except Exception as e:
                    print(f"Error encoding command JSON: {e}", flush=True)
            
            # System info request handling
            elif data.get('type') == 'request_info':
                if self.info_request_callback:
                    self.info_request_callback(data)
                
        except Exception as e:
            print(f"Error handling WebSocket message: {e}")

    def send_message(self, data):
        """Send message to WebSocket"""
        if self.websocket_connection and self.is_connected:
            try:
                message = json.dumps(data, ensure_ascii=False)
                self.websocket_connection.send(message)

                msg_type = data.get('type', '')
                if msg_type == 'start_transcribe':
                    self.audio_streaming = True
                    self._audio_logged = False  # Reset audio logging flag
                    print("SEND: start_transcribe")
                elif msg_type == 'stop_transcribe':
                    self.audio_streaming = False
                    self._audio_logged = False  # Reset audio logging flag
                    print("SEND: stop_transcribe")
                elif msg_type == 'send_audio':
                    # Only log audio streaming once to avoid spam
                    if not hasattr(self, '_audio_logged') or not self._audio_logged:
                        self._audio_logged = True
                        print("SEND: audio streaming")
                elif msg_type == 'request_command':
                    print("SEND: 명령어 변환 요청")

                return True
            except Exception as e:
                print(f"Error sending WebSocket message: {e}")
                return False
        return False

    def close(self):
        """Close WebSocket connection"""
        if self.websocket_connection:
            self.websocket_connection.close()