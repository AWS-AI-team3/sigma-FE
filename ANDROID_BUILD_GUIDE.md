# Android 빌드 및 실행 가이드

## 1. MediaPipe 모델 파일 다운로드

먼저 MediaPipe Hand Landmarker 모델 파일을 다운로드해야 합니다:

```bash
# assets 폴더 생성
mkdir -p android/app/src/main/assets/

# 모델 파일 다운로드 (Linux/Mac)
cd android/app/src/main/assets/
curl -O https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task

# Windows PowerShell
cd android/app/src/main/assets/
Invoke-WebRequest -Uri "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task" -OutFile "hand_landmarker.task"
```

또는 수동으로:
1. https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task 에서 다운로드
2. `android/app/src/main/assets/hand_landmarker.task` 경로에 저장

## 2. 빌드

### 의존성 설치
```bash
flutter pub get
```

### APK 빌드
```bash
flutter build apk
```

### 디버그 실행 (실제 디바이스 필요)
```bash
flutter run
```

**중요**: 제스처 제어는 실제 Android 디바이스에서만 테스트 가능합니다. 에뮬레이터는 카메라 기능이 제한적입니다.

## 3. 필요한 권한 설정

앱을 처음 실행하면 다음 권한을 설정해야 합니다:

### 3.1 오버레이 권한
1. 앱 화면에서 "오버레이 권한" 행의 "설정" 버튼 클릭
2. "다른 앱 위에 표시" 권한 활성화
3. 앱으로 돌아오기

### 3.2 접근성 권한
1. 앱 화면에서 "접근성 권한" 행의 "설정" 버튼 클릭
2. "SIGMA 제스처 제어" 찾기
3. 접근성 서비스 활성화
4. 앱으로 돌아오기

### 3.3 카메라 권한
앱 실행 시 자동으로 요청됩니다. 허용해주세요.

## 4. 서비스 시작

모든 권한이 활성화되면:
1. "서비스 시작" 버튼 클릭
2. 알림 바에 "SIGMA 제스처 제어" 알림이 표시됨
3. 화면에 커서(엄지 위치)가 표시됨
4. 엄지와 검지를 붙이면 터치 이벤트 발생

## 5. 테스트

### 유튜브 앱에서 테스트:
1. 서비스를 시작한 상태에서 홈 버튼을 눌러 앱 목록으로 이동
2. 유튜브 앱 실행
3. 손을 카메라에 보이도록 위치
4. 엄지 끝에 커서가 표시됨
5. 엄지와 검지를 붙여 핀치 → 커서 위치에 터치 발생
6. 영상 재생/일시정지 등을 제스처로 제어 가능

## 6. 트러블슈팅

### 커서가 보이지 않음
- 오버레이 권한이 활성화되어 있는지 확인
- 서비스가 실행 중인지 확인 (알림 바에 알림이 있어야 함)

### 터치가 작동하지 않음
- 접근성 권한이 활성화되어 있는지 확인
- 설정 → 접근성 → SIGMA 제스처 제어가 ON 상태인지 확인

### 손 인식이 안됨
- 카메라 권한이 허용되어 있는지 확인
- 로그캣에서 다음 메시지 확인:
  ```
  D/GestureService: MediaPipe initialized successfully
  D/GestureService: Camera started
  ```
- 손을 카메라에 잘 보이도록 위치 조정
- 조명이 충분한지 확인

### 빌드 오류
```bash
# 캐시 정리 후 재빌드
flutter clean
flutter pub get
flutter build apk
```

## 7. 로그 확인

```bash
# Android Studio Logcat 또는 adb 사용
adb logcat | grep -i "GestureService\|CameraHelper\|AccessibilityGesture"
```

주요 로그 메시지:
- `MediaPipe initialized successfully` - MediaPipe 초기화 성공
- `Camera started` - 카메라 시작됨
- `Service created and started` - 서비스 시작됨
