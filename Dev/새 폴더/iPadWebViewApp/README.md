# iPad WebView with Hand Tracking

아이패드용 제스처 제어 웹뷰 앱입니다.

## 주요 기능

### 1. Split View UI
- **왼쪽 사이드바** (30% 너비)
  - 채팅: 메시지 입력 및 대화
  - 즐겨찾기: 자주 방문하는 웹사이트
  - 설정: 손 추적 및 제스처 설정

- **오른쪽 웹뷰** (70% 너비)
  - WKWebView로 웹 페이지 표시
  - 제스처로 제어 가능

### 2. 손 추적 및 제스처 제어
- **Vision Framework** 사용
- **엄지 손가락**: 커서 이동
- **엄지-검지 핀치**: 클릭 동작
- 실시간 손 위치 추적

### 3. 가상 커서
- 엄지 위치를 따라다니는 커서
- 핀치 시 색상 변경 (파란색 → 녹색)

## 기술 스택

- **언어**: Swift
- **UI 프레임워크**: SwiftUI + UIKit
- **웹뷰**: WKWebView
- **손 추적**: Vision Framework (VNDetectHumanHandPoseRequest)
- **카메라**: AVFoundation

## 필수 요구사항

- iOS 14.0 이상
- iPad (전면 카메라 필수)
- 카메라 권한 승인

## 파일 구조

```
iPadWebViewApp/
├── Sources/
│   ├── iPadWebViewApp.swift          # 앱 진입점
│   ├── ContentView.swift              # 메인 Split View
│   ├── SidebarView.swift              # 왼쪽 사이드바 (채팅/즐겨찾기/설정)
│   ├── HandTrackingManager.swift     # 손 추적 및 제스처 인식
│   └── WebViewContainer.swift        # 웹뷰 + 커서 오버레이
├── Resources/
└── Info.plist                         # 카메라 권한 설정
```

## 사용 방법

1. **Xcode 프로젝트 생성**
   - File → New → Project → iOS → App 선택
   - Interface: SwiftUI, Language: Swift 선택
   - iPad 타겟 설정

2. **파일 추가**
   - Sources 폴더의 모든 .swift 파일을 프로젝트에 추가
   - Info.plist 설정 추가

3. **빌드 및 실행**
   - iPad 시뮬레이터 또는 실제 iPad에서 실행
   - 카메라 권한 승인

4. **제스처 사용**
   - 카메라를 향해 손을 펴고 엄지를 움직여 커서 이동
   - 엄지와 검지를 가까이 붙여 클릭

## 커스터마이징

### 핀치 감도 조정
`HandTrackingManager.swift`의 `pinchThreshold` 값 조정:
```swift
private let pinchThreshold: CGFloat = 50.0  // 픽셀 단위
```

### 레이아웃 비율 조정
`ContentView.swift`의 프레임 너비 조정:
```swift
.frame(width: geometry.size.width * 0.3)  // 사이드바
.frame(width: geometry.size.width * 0.7)  // 웹뷰
```

## 주의사항

- 실제 iPad 기기에서 테스트 필요 (시뮬레이터는 카메라 미지원)
- 충분한 조명 환경에서 사용
- 카메라와 30-50cm 거리 유지 권장
