import '../constants/app_constants.dart';

/// UI 제스처 선택과 서버 모션 코드 간의 매핑을 처리하는 클래스
class GestureMapping {
  
  /// UI 드롭다운 선택 값을 서버 모션 코드로 변환
  static String uiToMotionCode(String uiValue) {
    switch (uiValue) {
      case AppConstants.gestureThumbIndex:
        return AppConstants.motionM1;  // 엄지+검지 핀치
      case AppConstants.gestureThumbMiddle:
        return AppConstants.motionM2;  // 엄지+중지 핀치
      case AppConstants.gestureThumbPinky:
        return AppConstants.motionM3;  // 엄지+새끼 핀치
      case AppConstants.gestureUnassigned:
      default:
        return AppConstants.motionUnassigned;
    }
  }
  
  /// 서버 모션 코드를 UI 드롭다운 선택 값으로 변환
  static String motionCodeToUi(String motionCode) {
    switch (motionCode) {
      case AppConstants.motionM1:
        return AppConstants.gestureThumbIndex;  // 엄지+검지 핀치
      case AppConstants.motionM2:
        return AppConstants.gestureThumbMiddle;  // 엄지+중지 핀치
      case AppConstants.motionM3:
        return AppConstants.gestureThumbPinky;  // 엄지+새끼 핀치
      case AppConstants.motionUnassigned:
      default:
        return AppConstants.gestureUnassigned;
    }
  }
}