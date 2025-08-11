# SIGMA Flutter UI

SIGMA 제스처 컨트롤 앱의 Flutter UI 구현 - Figma 디자인 1:1 복원

## 설치 및 실행

### 1. Flutter 설치
```bash
# Windows에서 Flutter 설치
# https://docs.flutter.dev/get-started/install/windows

# 또는 Chocolatey 사용
choco install flutter

# 설치 확인
flutter --version
flutter doctor
```

### 2. 프로젝트 실행
```bash
cd flutter_ui

# 의존성 설치
flutter pub get

# 앱 실행 (데스크톱)
flutter run -d windows
# 또는
flutter run -d macos
# 또는
flutter run -d linux
```

### 3. 빌드
```bash
# Windows 앱 빌드
flutter build windows

# macOS 앱 빌드  
flutter build macos

# Linux 앱 빌드
flutter build linux
```

## 구현된 기능

### ✅ Figma 디자인 완벽 복원
- 정확한 색상 (#FAFAFA, #0004FF, #F0EEFF, #2E2981)
- Material Design 3 그림자 효과
- Google Fonts (Inter, Poppins, Roboto)
- 실제 SIGMA 로고 이미지 사용
- 픽셀 퍼펙트 레이아웃

### 🎨 디자인 요소
- **배경**: #FAFAFA (연한 회색)
- **메인 카드**: 둥근 모서리 76px, Material 그림자
- **로고**: 90x90px 원형, 실제 Figma 이미지
- **브랜딩**: SIGMA (Inter Black 48px) + 색상 강조 부제목
- **로그인 섹션**: 연보라색 배경 #F0EEFF, 둥근 모서리 44px
- **Google 버튼**: 점선 테두리 스타일

### 📱 반응형 디자인
- 데스크톱 앱 크기에 최적화
- 고해상도 디스플레이 지원
- 다양한 화면 크기 대응

## 파일 구조
```
flutter_ui/
├── lib/
│   ├── main.dart              # 앱 진입점
│   ├── screens/
│   │   └── login_screen.dart  # 로그인 화면 (Figma 구현)
│   └── widgets/               # 재사용 위젯들
├── assets/
│   └── images/
│       └── sigma_logo.png     # 실제 SIGMA 로고
└── pubspec.yaml               # 프로젝트 설정
```

## 다음 단계
1. 메인 화면 구현
2. 제스처 제어 화면 구현  
3. 음성 제어 화면 구현
4. 오버레이 기능 연동 (네이티브 플러그인)