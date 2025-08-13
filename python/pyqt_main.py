"""
PyQt6-based main window for gesture control
Enhanced version with modern UI styling
"""

import sys
import platform
import os
from PyQt6.QtWidgets import (QApplication, QMainWindow, QVBoxLayout, QHBoxLayout, 
                           QPushButton, QLabel, QWidget, QFrame, QMessageBox, QTextEdit, QTabWidget)
from PyQt6.QtCore import Qt, pyqtSignal, QTimer
from PyQt6.QtGui import QFont, QPalette, QColor, QPixmap

# Windows DPI 인식 설정 (한 번만 실행)
_DPI_INITIALIZED = False

def setup_dpi_awareness():
    global _DPI_INITIALIZED
    if not _DPI_INITIALIZED and platform.system() == "Windows":
        try:
            from ctypes import windll
            windll.shcore.SetProcessDpiAwareness(1)
        except:
            pass
        os.environ.setdefault("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
        os.environ.setdefault("QT_SCALE_FACTOR", "1")
        _DPI_INITIALIZED = True

from simple_overlay import SimpleHandOverlay
# Voice UI widget는 현재 경로에 없으므로 주석 처리
# from voice_ui_widget import VoiceUIWidget
from config import APP_NAME, WINDOW_WIDTH, WINDOW_HEIGHT


class PyQtMainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.hand_overlay = None
        self.current_user = {'name': 'User', 'email': 'user@example.com'}  # Simplified user info
        self.is_authenticated = False
        self.setup_dark_theme()
        self.init_ui()
        
    def setup_dark_theme(self):
        """Set up modern dark theme from external stylesheet"""
        try:
            style_path = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'styles', 'dark_theme.qss')
            style_path = os.path.abspath(style_path)
            if os.path.exists(style_path):
                with open(style_path, 'r', encoding='utf-8') as f:
                    self.setStyleSheet(f.read())
            else:
                # Fallback to inline styles
                self.setStyleSheet("""
                    QMainWindow { background-color: #2b2b2b; color: #ffffff; }
                    QWidget { background-color: #2b2b2b; color: #ffffff; }
                    QPushButton { background-color: #404040; border: 2px solid #606060; 
                                border-radius: 8px; padding: 12px 24px; font-size: 14px; 
                                font-weight: bold; color: #ffffff; }
                    QPushButton:hover { background-color: #505050; border-color: #707070; }
                    QLabel { color: #ffffff; background: transparent; }
                    QFrame { background-color: #353535; border-radius: 10px; padding: 20px; }
                """)
        except Exception:
            # Minimal fallback
            self.setStyleSheet("QMainWindow { background-color: #2b2b2b; color: #ffffff; }")
        
    def init_ui(self):
        self.setWindowTitle(APP_NAME)
        self.setGeometry(100, 100, WINDOW_WIDTH, WINDOW_HEIGHT)
        
        # Central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Show login page initially
        self.show_login_page()
    
    def show_login_page(self):
        """Display SIGMA login page matching Figma design"""
        self.clear_current_layout()
        
        # Create new central widget - this IS the app
        central_widget = QWidget()
        central_widget.setStyleSheet("""
            QWidget {
                background-color: #fafafa;
            }
        """)
        self.setCentralWidget(central_widget)
        
        # Main layout
        layout = QVBoxLayout(central_widget)
        layout.setContentsMargins(40, 60, 40, 40)
        layout.setSpacing(20)
        
        # Logo and branding section
        brand_layout = QVBoxLayout()
        brand_layout.setSpacing(5)
        
        # SIGMA logo section
        logo_layout = QHBoxLayout()
        logo_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        # SIGMA Logo from Figma
        logo_label = QLabel()
        logo_label.setFixedSize(90, 90)
        logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        # Load logo image
        logo_path = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'images', 'sigma_logo.png')
        logo_path = os.path.abspath(logo_path)
        
        if os.path.exists(logo_path):
            pixmap = QPixmap(logo_path)
            scaled_pixmap = pixmap.scaled(90, 90, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
            logo_label.setPixmap(scaled_pixmap)
        else:
            # Fallback text if image not found
            logo_label.setText("SIGMA")
            logo_label.setStyleSheet("""
                QLabel {
                    background-color: #0004ff;
                    border-radius: 45px;
                    font-size: 16px;
                    color: white;
                    font-weight: bold;
                }
            """)
        logo_layout.addWidget(logo_label)
        
        # SIGMA text
        sigma_label = QLabel("SIGMA")
        sigma_font = QFont("Inter", 48, QFont.Weight.Black)
        sigma_label.setFont(sigma_font)
        sigma_label.setStyleSheet("color: #000000; margin-left: 10px;")
        logo_layout.addWidget(sigma_label)
        
        brand_layout.addLayout(logo_layout)
        
        # Subtitle with colored letters
        subtitle1 = QLabel("Smart Interactive Gesture")
        subtitle1.setAlignment(Qt.AlignmentFlag.AlignCenter)
        subtitle1_font = QFont("Poppins", 11, QFont.Weight.DemiBold)
        subtitle1.setFont(subtitle1_font)
        subtitle1.setStyleSheet("color: #000000;")
        
        subtitle2 = QLabel("Management Assistant")
        subtitle2.setAlignment(Qt.AlignmentFlag.AlignCenter)
        subtitle2_font = QFont("Poppins", 11, QFont.Weight.DemiBold)
        subtitle2.setFont(subtitle2_font)
        subtitle2.setStyleSheet("color: #000000;")
        
        brand_layout.addWidget(subtitle1)
        brand_layout.addWidget(subtitle2)
        layout.addLayout(brand_layout)
        
        # Login section
        login_frame = QFrame()
        login_frame.setFixedSize(370, 200)
        login_frame.setStyleSheet("""
            QFrame {
                background-color: #f0eeff;
                border-radius: 44px;
                border: none;
            }
        """)
        
        login_layout = QVBoxLayout(login_frame)
        login_layout.setContentsMargins(30, 30, 30, 30)
        login_layout.setSpacing(20)
        
        # Login title
        login_title = QLabel("Login")
        login_font = QFont("SF Pro Rounded", 32, QFont.Weight.Bold)
        login_title.setFont(login_font)
        login_title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        login_title.setStyleSheet("color: #2e2981;")
        login_layout.addWidget(login_title)
        
        # Google login button (styled as dashed border)
        google_button = QPushButton("G  Continue with Google")
        google_button.setFixedSize(310, 60)
        google_button.setStyleSheet("""
            QPushButton {
                background-color: transparent;
                border: 2px dashed #0004ff;
                border-radius: 8px;
                color: #2e2981;
                font-size: 16px;
                font-weight: 500;
                padding: 10px;
            }
            QPushButton:hover {
                background-color: rgba(0, 4, 255, 0.1);
            }
            QPushButton:pressed {
                background-color: rgba(0, 4, 255, 0.2);
            }
        """)
        google_button.clicked.connect(self.on_login)
        login_layout.addWidget(google_button, alignment=Qt.AlignmentFlag.AlignCenter)
        
        layout.addWidget(login_frame, alignment=Qt.AlignmentFlag.AlignCenter)
    
    def show_main_page(self):
        """Display main page after login with tabs"""
        self.clear_current_layout()
        
        # Create new central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Main layout
        layout = QVBoxLayout(central_widget)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(15)
        
        # User info frame
        user_frame = QFrame()
        user_layout = QVBoxLayout(user_frame)
        
        welcome_label = QLabel(f"환영합니다, {self.current_user['name']}님!")
        welcome_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        welcome_font = QFont()
        welcome_font.setPointSize(16)
        welcome_label.setFont(welcome_font)
        user_layout.addWidget(welcome_label)
        
        layout.addWidget(user_frame)
        
        # Create tab widget
        self.tab_widget = QTabWidget()
        
        # Gesture control tab
        gesture_tab = QWidget()
        self.create_gesture_tab(gesture_tab)
        self.tab_widget.addTab(gesture_tab, "🖐 제스처 제어")
        
        # Voice control tab - 임시로 비활성화
        # voice_tab = VoiceUIWidget()
        # self.tab_widget.addTab(voice_tab, "🎤 음성 제어")
        
        layout.addWidget(self.tab_widget)
        
        # Control buttons frame
        control_frame = QFrame()
        control_layout = QHBoxLayout(control_frame)
        control_layout.setSpacing(15)
        
        # Help button
        help_button = QPushButton("도움말")
        help_button.setFixedSize(120, 45)
        help_button.clicked.connect(self.show_help)
        control_layout.addWidget(help_button)
        
        # Settings button  
        settings_button = QPushButton("설정")
        settings_button.setFixedSize(120, 45)
        settings_button.clicked.connect(self.show_settings)
        control_layout.addWidget(settings_button)
        
        # Logout button
        logout_button = QPushButton("종료")
        logout_button.setFixedSize(120, 45)
        logout_button.clicked.connect(self.logout)
        control_layout.addWidget(logout_button)
        
        # Center control buttons
        control_button_layout = QHBoxLayout()
        control_button_layout.addStretch()
        control_button_layout.addWidget(control_frame)
        control_button_layout.addStretch()
        layout.addLayout(control_button_layout)
    
    def create_gesture_tab(self, tab_widget):
        """제스처 제어 탭 생성"""
        layout = QVBoxLayout(tab_widget)
        layout.setContentsMargins(40, 40, 40, 40)
        layout.setSpacing(20)
        
        # Info label
        info_label = QLabel("손 제스처로 마우스를 제어하세요")
        info_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        info_font = QFont()
        info_font.setPointSize(14)
        info_label.setFont(info_font)
        layout.addWidget(info_label)
        
        # Spacing
        layout.addStretch()
        
        # Main tracking button
        self.start_button = QPushButton("🖐 손 제스처 추적 시작")
        self.start_button.setFixedSize(250, 70)
        self.start_button.clicked.connect(self.start_tracking)
        
        self.stop_button = QPushButton("⏹ 추적 중지")
        self.stop_button.setFixedSize(250, 70)
        self.stop_button.clicked.connect(self.stop_tracking)
        self.stop_button.hide()
        
        # Center main buttons
        main_button_layout = QHBoxLayout()
        main_button_layout.addStretch()
        main_button_layout.addWidget(self.start_button)
        main_button_layout.addWidget(self.stop_button)
        main_button_layout.addStretch()
        layout.addLayout(main_button_layout)
        
        layout.addStretch()
    
    def clear_current_layout(self):
        """Clear current layout"""
        # Since we create a new central widget each time, 
        # just delete the old central widget if it exists
        old_widget = self.centralWidget()
        if old_widget:
            old_widget.deleteLater()
            QApplication.processEvents()
        
    def on_login(self):
        """Handle login button click"""
        self.is_authenticated = True
        self.show_main_page()
        
    def show_help(self):
        """Show help dialog"""
        help_text = """제스처 가이드:

🖐 검지손가락: 마우스 커서 이동
👆 엄지+검지 터치: 좌클릭  
🖖 엄지+중지 터치: 우클릭
📜 엄지+검지+중지 터치: 스크롤 모드
⬆️ 스크롤 중 위로 이동: 위로 스크롤
⬇️ 스크롤 중 아래로 이동: 아래로 스크롤
✊ 엄지+검지 꾹 누르기: 드래그 시작/끝

💡 팁: 자연스럽게 손동작을 하세요!"""
        
        msg = QMessageBox()
        msg.setWindowTitle("제스처 도움말")
        msg.setText(help_text)
        msg.setStyleSheet(self.styleSheet())
        msg.exec()
        
    def show_settings(self):
        """Show settings (placeholder)"""
        msg = QMessageBox()
        msg.setWindowTitle("설정")
        msg.setText("설정 기능은 추후 업데이트 예정입니다.")
        msg.setStyleSheet(self.styleSheet())
        msg.exec()
        
    def logout(self):
        """Return to login page"""
        if self.hand_overlay:
            self.hand_overlay.stop_tracking()
        self.is_authenticated = False
        self.show_login_page()
        
    def start_tracking(self):
        """Start hand tracking with overlay"""
        if self.hand_overlay is None:
            self.hand_overlay = SimpleHandOverlay()
            # Set callback for remote tracking stop
            self.hand_overlay.set_tracking_stop_callback(self.on_remote_tracking_stopped)
        
        self.hand_overlay.start_tracking()
        self.start_button.hide()
        self.stop_button.show()
        
    def stop_tracking(self):
        """Stop hand tracking"""
        if self.hand_overlay:
            self.hand_overlay.stop_tracking()
        
        self.stop_button.hide()
        self.start_button.show()
        
    def on_remote_tracking_stopped(self):
        """Handle tracking stopped from remote control"""
        # Update button states to match the stop_tracking method
        self.stop_button.hide()
        self.start_button.show()
        
    def closeEvent(self, event):
        """Handle window close event"""
        if self.hand_overlay:
            self.hand_overlay.stop_tracking()
        event.accept()


def main():
    setup_dpi_awareness()
    app = QApplication(sys.argv)
    window = PyQtMainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()