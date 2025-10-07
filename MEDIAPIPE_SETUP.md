# MediaPipe 모델 파일 설정

## 1. 모델 파일 다운로드

MediaPipe Hand Landmarker 모델을 다운로드해야 합니다:

```bash
# android/app/src/main/assets/ 폴더 생성
mkdir -p android/app/src/main/assets/

# 모델 파일 다운로드
cd android/app/src/main/assets/
curl -O https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task
```

또는 수동으로:
1. https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task 에서 다운로드
2. `android/app/src/main/assets/hand_landmarker.task` 경로에 저장

## 2. 빌드

모델 파일을 추가한 후 프로젝트를 빌드합니다:

```bash
flutter build apk
```

또는 디버그 실행:

```bash
flutter run
```

## 3. 확인

로그캣에서 다음 메시지를 확인:
```
D/GestureService: MediaPipe initialized successfully
D/GestureService: Camera started
```
