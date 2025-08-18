import 'package:flutter/foundation.dart';
import '../services/python_service.dart';
import '../services/settings_service.dart';
import '../utils/logger.dart';
import '../utils/gesture_mapping.dart';

class SettingsProvider with ChangeNotifier {
  bool _showMouseCursor = true;
  bool _showSkeleton = false;
  bool _useLeftHand = true;
  
  String _leftClickValue = '선택 안함';
  String _rightClickValue = '선택 안함';
  String _wheelScrollValue = '선택 안함';
  String _recordStartValue = '선택 안함';
  String _recordStopValue = '선택 안함';

  // Getters
  bool get showMouseCursor => _showMouseCursor;
  bool get showSkeleton => _showSkeleton;
  bool get useLeftHand => _useLeftHand;
  String get leftClickValue => _leftClickValue;
  String get rightClickValue => _rightClickValue;
  String get wheelScrollValue => _wheelScrollValue;
  String get recordStartValue => _recordStartValue;
  String get recordStopValue => _recordStopValue;

  /// 서버에서 모션 설정 불러오기
  Future<void> loadMotionSettingsFromServer() async {
    try {
      final result = await SettingsService.getMotionSettings();
      if (result != null && result['sucess'] == true) {
        final data = result['data'];
        
        // 서버 데이터로 설정 업데이트 (로컬 저장 없이)
        _showSkeleton = data['showSkeleton'] ?? false;
        _showMouseCursor = data['showCursor'] ?? true;
        
        // 서버 모션 코드를 UI 값으로 변환
        _leftClickValue = GestureMapping.motionCodeToUi(data['motionLeftClick'] ?? '');
        _rightClickValue = GestureMapping.motionCodeToUi(data['motionRightClick'] ?? '');
        _wheelScrollValue = GestureMapping.motionCodeToUi(data['motionWheelScroll'] ?? '');  // 붙여넣기로 사용
        
        print('Loaded from server - showSkeleton: $_showSkeleton, showMouseCursor: $_showMouseCursor');
        print('Motion mappings - leftClick: $_leftClickValue, rightClick: $_rightClickValue, paste: $_wheelScrollValue');
        
        // Python 프로세스에 스켈레톤 설정 전달
        PythonService.updateSkeletonDisplay(_showSkeleton);
        
        notifyListeners();
        Logger.info('서버에서 모션 설정 로드 완료', 'SETTINGS');
      } else {
        Logger.error('서버에서 모션 설정 로드 실패', 'SETTINGS');
      }
    } catch (e) {
      Logger.error('서버 모션 설정 로드 오류', 'SETTINGS', e);
    }
  }


  void setShowMouseCursor(bool value) {
    print('Setting showMouseCursor to: $value');
    _showMouseCursor = value;
    notifyListeners();
  }

  void setShowSkeleton(bool value) {
    print('Setting showSkeleton to: $value');
    _showSkeleton = value;
    
    // Python 프로세스에 스켈레톤 표시 설정 업데이트
    PythonService.updateSkeletonDisplay(value);
    
    notifyListeners();
  }

  void setUseLeftHand(bool value) {
    _useLeftHand = value;
    notifyListeners();
  }

  void setLeftClickValue(String value) {
    _leftClickValue = value;
    notifyListeners();
  }

  void setRightClickValue(String value) {
    _rightClickValue = value;
    notifyListeners();
  }

  void setWheelScrollValue(String value) {
    _wheelScrollValue = value;
    notifyListeners();
  }

  void setRecordStartValue(String value) {
    _recordStartValue = value;
    notifyListeners();
  }

  void setRecordStopValue(String value) {
    _recordStopValue = value;
    notifyListeners();
  }

  Future<void> saveAllSettings() async {
    // 서버에 스켈레톤 설정 저장
    final skeletonSuccess = await SettingsService.saveSkeletonSetting(_showSkeleton);
    if (skeletonSuccess) {
      Logger.info('서버에 스켈레톤 설정 저장 완료', 'SETTINGS');
    } else {
      Logger.error('서버에 스켈레톤 설정 저장 실패', 'SETTINGS');
    }
    
    // 서버에 커서 설정 저장
    final cursorSuccess = await SettingsService.saveCursorSetting(_showMouseCursor);
    if (cursorSuccess) {
      Logger.info('서버에 커서 설정 저장 완료', 'SETTINGS');
    } else {
      Logger.error('서버에 커서 설정 저장 실패', 'SETTINGS');
    }
    
    // 서버에 모션 매핑 설정 저장
    final motionSuccess = await SettingsService.saveMotionSettings(
      leftClick: _leftClickValue,     // 좌클릭 제스처 (motionLeftClick)
      rightClick: _rightClickValue,   // 우클릭 제스처 (motionRightClick)
      paste: _wheelScrollValue,       // 붙여넣기 제스처 (motionWheelScroll)
    );
    if (motionSuccess) {
      Logger.info('서버에 모션 매핑 설정 저장 완료', 'SETTINGS');
    } else {
      Logger.error('서버에 모션 매핑 설정 저장 실패', 'SETTINGS');
    }
  }
}