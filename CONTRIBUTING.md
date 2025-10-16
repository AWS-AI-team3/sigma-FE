# 협업 가이드 (Contributing Guide)

## 🍎 iOS 개발 시 필수 사항

### 문제: 다른 Apple Developer 계정으로 개발할 때

각 개발자는 **자신의 Apple Developer 계정**을 사용해야 하므로, 코드 서명 설정이 달라집니다.

### 해결 방법

#### 1️⃣ 최초 설정 (클론 후 1회만)

```bash
# 저장소 클론
git clone https://github.com/AWS-AI-team3/sigma-FE.git
cd gesture_browser

# Flutter 의존성
flutter pub get

# iOS 의존성
cd ios
pod install
cd ..

# Xcode 프로젝트 열기
open ios/Runner.xcworkspace
```

#### 2️⃣ Xcode에서 Team 설정

1. **왼쪽 네비게이터**에서 `Runner` 프로젝트 클릭
2. **TARGETS** → `Runner` 선택
3. **Signing & Capabilities** 탭 클릭
4. **Team** 드롭다운에서 **자신의 팀** 선택

**Apple ID가 없다면?**
- Xcode → Settings (⌘ + ,) → Accounts
- 왼쪽 하단 `+` 버튼 → Apple ID 추가
- 무료 Personal Team 자동 생성

#### 3️⃣ Bundle Identifier 충돌 시

기본값 `com.gesture.gestureBrowser`가 이미 사용 중이라면:

```
변경 예시:
com.gesture.gestureBrowser
  ↓
com.yourname.gestureBrowser
```

---

## ⚠️ Git 커밋 시 주의사항

### ❌ 절대 커밋하지 말 것

```bash
# Team ID가 포함된 project.pbxproj 변경사항
ios/Runner.xcodeproj/project.pbxproj  # Team 설정 변경 시

# Xcode 사용자 데이터
ios/Runner.xcodeproj/xcuserdata/
ios/Runner.xcworkspace/xcuserdata/
```

### ✅ 커밋 전 확인

```bash
# 변경사항 확인
git status

# Team 설정이 변경되었다면 되돌리기
git diff ios/Runner.xcodeproj/project.pbxproj

# DEVELOPMENT_TEAM이 보인다면:
git checkout ios/Runner.xcodeproj/project.pbxproj
```

---

## 🔄 일상 워크플로우

### 개발 시작

```bash
git pull origin main
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### 코드 변경 후 커밋

```bash
# Staging
git add .

# Team 설정 변경사항 제외
git reset ios/Runner.xcodeproj/project.pbxproj

# Commit
git commit -m "feat: 새로운 기능 추가"

# Push
git push origin your-branch
```

---

## 🚨 자주 발생하는 에러

### 1. Signing Error

```
❌ Signing for "Runner" requires a development team.
```

**해결:**
- Xcode → Signing & Capabilities → Team 선택

### 2. Provisioning Profile Error

```
❌ No profiles for 'com.gesture.gestureBrowser' were found
```

**해결:**
- Bundle Identifier를 고유한 값으로 변경
- 예: `com.yourname.gestureBrowser`

### 3. CocoaPods 에러

```bash
cd ios
pod deintegrate
pod install
cd ..
```

---

## 📝 Pull Request 체크리스트

- [ ] `flutter analyze` 통과
- [ ] 새로운 기능에 대한 테스트 추가
- [ ] README 업데이트 (필요 시)
- [ ] iOS Team 설정 변경사항 제외
- [ ] 불필요한 디버그 코드 제거

---

## 💡 팁

### 여러 개발자가 동시에 작업할 때

1. **Branch 전략**
   ```bash
   main (프로덕션)
   ├── develop (개발)
   └── feature/your-feature (기능 개발)
   ```

2. **iOS 설정은 로컬에만**
   - Team 설정은 각자 로컬에서만 변경
   - `.gitignore`가 자동으로 대부분 보호
   
3. **문제 발생 시**
   - 먼저 `flutter clean` 시도
   - iOS 의존성 재설치: `cd ios && pod install`
   - Xcode 캐시 삭제: Product → Clean Build Folder (⇧⌘K)

---

## 🎯 목표

**모든 개발자가 클론 후 5분 안에 실행 가능한 환경 유지!**

질문이 있다면 Issue를 열어주세요. 🙏
