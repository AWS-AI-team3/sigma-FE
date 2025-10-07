# Android 태블릿 전환 개발 가이드

## 📋 개요

Windows 데스크톱 앱을 Android 태블릿 앱으로 전환하는 프로젝트입니다.

**핵심 기능:**
- 백그라운드에서 손 제스처 인식
- 엄지 끝에 커서 오버레이 표시
- 핀치 제스처로 화면 터치 (YouTube 등 다른 앱 제어)

---

## 🏗️ 아키텍처

```
[SIGMA Android App]
├── GestureBackgroundService (백그라운드 서비스)
│   ├── 카메라로 손 추적 (TODO: MediaPipe 구현 필요)
│   ├── 엄지 위치 추출
│   └── CursorOverlayManager 호출
│
├── CursorOverlayManager (커서 오버레이)
│   ├── WindowManager로 다른 앱 위에 표시
│   └── 엄지 위치에 커서 이동
│
├── AccessibilityGestureService (터치 실행)
│   ├── 핀치 감지 시 터치 실행
│   └── 드래그 제스처 지원
│
└── GestureServiceModule (Flutter Bridge)
    └── Flutter ↔ Android 통신
```

---

## 📁 생성된 파일 (프론트엔드 개발자 작업 필요)

### ✅ 완료된 파일 (기본 구조)

#### **Android Native (Kotlin):**
```
android/app/src/main/kotlin/com/example/sigma_flutter_ui/
├── GestureBackgroundService.kt      ✅ 완료 (TODO: MediaPipe 추가 필요)
├── CursorOverlayManager.kt          ✅ 완료
├── AccessibilityGestureService.kt   ✅ 완료
├── GestureServiceModule.kt          ✅ 완료
└── MainActivity.kt                  ✅ 완료
```

#### **Flutter:**
```
lib/services/
└── gesture_control_service.dart     ✅ 완료
```

#### **Android 설정:**
```
android/app/src/main/AndroidManifest.xml  ✅ 권한 추가 완료
android/app/src/main/res/xml/
└── accessibility_service_config.xml      ✅ 완료
```

---

## 🔧 TODO: 프론트엔드 개발자가 구현해야 할 부분

### 1. **MediaPipe 손 추적 구현** (최우선 작업)

**위치:** `GestureBackgroundService.kt`

**TODO 부분:**
```kotlin
// TODO: MediaPipe 초기화 (프론트엔드 개발자가 구현)
// initializeMediaPipe()

// TODO: 카메라 시작 (프론트엔드 개발자가 구현)
// startBackgroundCamera()
```

**구현 방법:**
```kotlin
// GestureBackgroundService.kt 에 추가

import com.google.mediapipe.solutions.hands.Hands
import com.google.mediapipe.solutions.hands.HandsOptions

private lateinit var mediaPipeHands: Hands

private fun initializeMediaPipe() {
    val options = HandsOptions.builder()
        .setStaticImageMode(false)
        .setMaxNumHands(1)
        .setRunOnGpu(true)
        .build()

    mediaPipeHands = Hands(this, options)

    mediaPipeHands.setResultListener { result ->
        if (result.multiHandLandmarks().isNotEmpty()) {
            val landmarks = result.multiHandLandmarks()[0]

            // 엄지 끝 (랜드마크 4번)
            val thumbTip = landmarks.landmarkList[4]

            // 화면 좌표로 변환
            val screenX = (1 - thumbTip.x) * getScreenWidth()
            val screenY = thumbTip.y * getScreenHeight()

            // 커서 업데이트
            updateCursorPosition(screenX, screenY)

            // 제스처 분류
            val gesture = classifyGesture(landmarks.landmarkList)
            onGestureDetected(gesture)
        }
    }
}

private fun classifyGesture(landmarks: List<NormalizedLandmark>): String {
    val thumbTip = landmarks[4]
    val indexTip = landmarks[8]

    // 거리 계산
    val distance = sqrt(
        (thumbTip.x - indexTip.x).pow(2) +
        (thumbTip.y - indexTip.y).pow(2)
    )

    // 핀치 감지
    if (distance < 0.05) {  // 임계값
        return "thumb_index_pinch"
    }

    return "cursor"
}
```

**의존성 추가 (build.gradle.kts):**
```kotlin
dependencies {
    implementation("com.google.mediapipe:tasks-vision:0.10.9")
}
```

---

### 2. **커서 이미지 커스터마이징** (선택사항)

**위치:** `CursorOverlayManager.kt`

**현재 상태:**
```kotlin
// 임시: 기본 아이콘 사용
setImageResource(android.R.drawable.presence_online)
```

**커스텀 이미지 사용:**
1. `android/app/src/main/res/drawable/` 폴더에 `cursor_pointer.png` 추가
2. 코드 변경:
```kotlin
setImageResource(R.drawable.cursor_pointer)
```

---

### 3. **Flutter UI 구현** (필수)

**생성할 파일:** `lib/screens/service_control_screen.dart`

**예제 코드:**
```dart
import 'package:flutter/material.dart';
import '../services/gesture_control_service.dart';

class ServiceControlScreen extends StatefulWidget {
  @override
  State<ServiceControlScreen> createState() => _ServiceControlScreenState();
}

class _ServiceControlScreenState extends State<ServiceControlScreen> {
  bool _isServiceRunning = false;
  bool _isAccessibilityEnabled = false;
  bool _hasOverlayPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final accessibilityEnabled =
        await GestureControlService.checkAccessibilityEnabled();
    final overlayPermission =
        await GestureControlService.checkOverlayPermission();

    setState(() {
      _isAccessibilityEnabled = accessibilityEnabled;
      _hasOverlayPermission = overlayPermission;
    });
  }

  Future<void> _toggleService() async {
    if (_isServiceRunning) {
      await GestureControlService.stopService();
      setState(() => _isServiceRunning = false);
    } else {
      final success = await GestureControlService.startService();
      setState(() => _isServiceRunning = success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SIGMA 제스처 제어')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // 서비스 On/Off
            SwitchListTile(
              title: Text('백그라운드 제스처 인식'),
              value: _isServiceRunning,
              onChanged: (_) => _toggleService(),
            ),

            SizedBox(height: 20),

            // Accessibility 상태
            ListTile(
              title: Text('Accessibility Service'),
              trailing: _isAccessibilityEnabled
                  ? Icon(Icons.check, color: Colors.green)
                  : Icon(Icons.close, color: Colors.red),
            ),

            if (!_isAccessibilityEnabled)
              ElevatedButton(
                onPressed: GestureControlService.openAccessibilitySettings,
                child: Text('Accessibility 설정 열기'),
              ),

            SizedBox(height: 20),

            // 오버레이 권한 상태
            ListTile(
              title: Text('오버레이 권한'),
              trailing: _hasOverlayPermission
                  ? Icon(Icons.check, color: Colors.green)
                  : Icon(Icons.close, color: Colors.red),
            ),

            if (!_hasOverlayPermission)
              ElevatedButton(
                onPressed: GestureControlService.openOverlaySettings,
                child: Text('오버레이 권한 설정'),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

### 4. **main.dart 수정** (필수)

**기존 Windows 관련 코드 제거:**
```dart
// 삭제
import 'services/app_lifecycle_manager.dart';

// 삭제
await AppLifecycleManager.initialize();
```

**Android 서비스 UI 추가:**
```dart
import 'screens/service_control_screen.dart';

// 라우트 추가
routes: {
  '/service_control': (context) => ServiceControlScreen(),
  // 기존 라우트...
},
```

---

## 🚀 빌드 및 실행

### 1. **의존성 설치**
```bash
flutter pub get
```

### 2. **Android 빌드**
```bash
flutter build apk --debug
```

### 3. **실기기에서 실행**
```bash
flutter run
```

---

## ⚠️ 권한 설정 (사용자 안내 필요)

### 1. **Accessibility Service 활성화**
1. 설정 → 접근성
2. SIGMA 앱 찾기
3. 토글 ON

### 2. **오버레이 권한 허용**
1. 설정 → 앱
2. SIGMA → 고급 설정
3. 다른 앱 위에 표시 → 허용

---

## 📝 개발 순서 (권장)

### Phase 1: 기본 구조 테스트
1. ✅ Flutter 앱 빌드 및 실행
2. ✅ `GestureControlService` 테스트 (startService/stopService)
3. ✅ 권한 요청 플로우 확인

### Phase 2: MediaPipe 통합
1. MediaPipe 의존성 추가
2. 손 추적 구현 (`initializeMediaPipe()`)
3. 제스처 분류 로직 구현

### Phase 3: 커서 표시 테스트
1. 오버레이 권한 허용
2. 백그라운드 서비스 시작
3. 손을 움직여서 커서가 따라오는지 확인

### Phase 4: 터치 기능 테스트
1. Accessibility Service 활성화
2. 핀치 제스처로 터치 실행
3. YouTube 앱에서 재생/일시정지 테스트

---

## 🐛 문제 해결

### 1. "Unresolved reference: gesture_service"
→ `flutter clean && flutter pub get` 실행

### 2. "MediaPipe not found"
→ `android/app/build.gradle.kts`에 의존성 추가 확인

### 3. "Overlay permission denied"
→ 설정에서 수동으로 권한 허용 필요

### 4. "Accessibility Service not working"
→ 설정 → 접근성에서 SIGMA 앱 활성화 확인

---

## 📞 문의

- Python/AI 개발자: MediaPipe 모델 변환, 제스처 분류 알고리즘
- 프론트엔드 개발자: Kotlin Native 구현, Flutter UI

---

## 🎯 다음 단계

1. ✅ **현재 완료:** Android Native 기본 구조 생성
2. ⏳ **다음 작업:** MediaPipe 손 추적 구현
3. ⏳ **이후 작업:** Flutter UI 재구성
4. ⏳ **최종 작업:** YouTube 앱 제어 테스트

---

**작업 완료 후 확인 사항:**
- [ ] MediaPipe 손 추적 동작
- [ ] 커서 오버레이 표시
- [ ] 핀치 제스처로 터치 실행
- [ ] YouTube 앱 제어 가능
- [ ] 백그라운드에서 안정적으로 동작
