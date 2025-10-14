# Gesture Browser

얼굴 인증, 제스처 인식 등의 기능이 포함된 Flutter 프로젝트입니다.

## 📋 사전 요구사항

- **Flutter SDK** 3.0 이상
- **Dart SDK** 2.17 이상
- **Xcode** 14.0 이상 (iOS 빌드)
- **CocoaPods** (iOS 의존성 관리)

Flutter 설치 확인:
```bash
flutter doctor
```

## 🚀 설치 및 실행

### 1. 저장소 클론
```bash
git clone https://github.com/AWS-AI-team3/sigma-FE.git
cd gesture_browser
```

### 2. Flutter 의존성 설치
```bash
flutter pub get
```

### 3. iOS 의존성 설치 (macOS만 해당)
```bash
cd ios
pod install
cd ..
```

⚠️ **중요**: CocoaPods가 설치되어 있지 않다면:
```bash
sudo gem install cocoapods
```

### 4. 실행
```bash
# 사용 가능한 디바이스 확인
flutter devices

# iOS 시뮬레이터에서 실행
flutter run

# 특정 디바이스에서 실행
flutter run -d <device-id>
```

## 📱 주요 기능

- 📸 **얼굴 인증**: 카메라를 이용한 실시간 얼굴 인증
- 🖐️ **제스처 인식**: Hand Landmarker를 이용한 제스처 컨트롤
- 🌐 **웹 브라우저**: 내장 웹뷰 브라우저
- 🎤 **음성 녹음**: 오디오 녹음 및 전송 기능

## 🔧 문제 해결

### 빌드 오류 발생 시
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### 카메라 권한 오류
- **iOS**: `ios/Runner/Info.plist`에 카메라 권한이 설정되어 있는지 확인
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>얼굴 인증을 위해 카메라 접근이 필요합니다</string>
  ```

### CocoaPods 오류
```bash
cd ios
pod repo update
pod install --repo-update
cd ..
```

### Xcode 빌드 오류
1. Xcode에서 `ios/Runner.xcworkspace` 열기 (⚠️ `.xcodeproj`가 아닌 `.xcworkspace` 열기)
2. Signing & Capabilities에서 개발 팀 선택
3. Bundle Identifier 확인

## 📦 주요 의존성 패키지

- `camera`: 카메라 기능
- `http`: REST API 통신
- `google_sign_in`: Google 소셜 로그인
- `flutter_inappwebview`: 내장 웹뷰 브라우저
- `permission_handler`: 권한 관리
- `record`: 오디오 녹음

전체 의존성 목록은 `pubspec.yaml`을 참조하세요.

## 🏗️ 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── constants/                # 상수 정의
├── screens/                  # 화면 UI
│   ├── face_auth_screen.dart
│   ├── home_screen.dart
│   └── login_screen.dart
├── services/                 # 비즈니스 로직
│   ├── face_auth_service.dart
│   ├── api_client.dart
│   └── audio_recording_service.dart
└── widgets/                  # 재사용 가능한 위젯
```

## 🔐 환경 변수 설정 (선택사항)

민감한 정보(API 키 등)는 별도 파일로 관리하는 것을 권장합니다.

`lib/config/api_keys.dart` 파일 생성:
```dart
class ApiKeys {
  static const String baseUrl = 'YOUR_API_BASE_URL';
  static const String apiKey = 'YOUR_API_KEY';
}
```

## 📝 참고사항

- **main** 브랜치: 프로덕션 코드
- **ios** 브랜치: iOS 관련 개발
- **develop** 브랜치: 개발 중인 기능

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 AWS AI Team3에서 관리합니다.
