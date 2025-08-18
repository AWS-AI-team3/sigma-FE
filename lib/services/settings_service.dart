import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';
import '../services/auth_storage_service.dart';
import '../utils/logger.dart';
import '../utils/gesture_mapping.dart';

class SettingsService {
  
  /// 서버에서 모션 설정 불러오기
  static Future<Map<String, dynamic>?> getMotionSettings() async {
    try {
      final accessToken = await AuthStorageService.getValidAccessToken();
      if (accessToken == null) {
        Logger.error('Access token이 없습니다', 'SETTINGS');
        return null;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.settingsMotion}'),
        headers: {
          AppConstants.headerAccept: '*/*',
          AppConstants.headerAuthorization: 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Logger.info('모션 설정 불러오기 성공', 'SETTINGS');
        return data;
      } else {
        Logger.error('모션 설정 불러오기 실패: ${response.statusCode}', 'SETTINGS');
        return null;
      }
    } catch (error) {
      Logger.error('모션 설정 불러오기 오류', 'SETTINGS', error);
      return null;
    }
  }

  /// 서버에 스켈레톤 표시 설정 저장
  static Future<bool> saveSkeletonSetting(bool show) async {
    try {
      final accessToken = await AuthStorageService.getValidAccessToken();
      if (accessToken == null) {
        Logger.error('Access token이 없습니다', 'SETTINGS');
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.settingsSkeleton}'),
        headers: {
          AppConstants.headerAccept: '*/*',
          AppConstants.headerAuthorization: 'Bearer $accessToken',
          AppConstants.headerContentType: AppConstants.contentTypeJson,
        },
        body: json.encode({
          'show': show,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucess'] == true) {
          Logger.info('스켈레톤 설정 저장 성공: $show', 'SETTINGS');
          return true;
        } else {
          Logger.error('스켈레톤 설정 저장 실패: ${data['error']}', 'SETTINGS');
          return false;
        }
      } else {
        Logger.error('스켈레톤 설정 저장 실패: ${response.statusCode}', 'SETTINGS');
        return false;
      }
    } catch (error) {
      Logger.error('스켈레톤 설정 저장 오류', 'SETTINGS', error);
      return false;
    }
  }

  /// 서버에 커서 표시 설정 저장
  static Future<bool> saveCursorSetting(bool show) async {
    try {
      final accessToken = await AuthStorageService.getValidAccessToken();
      if (accessToken == null) {
        Logger.error('Access token이 없습니다', 'SETTINGS');
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.settingsCursor}'),
        headers: {
          AppConstants.headerAccept: '*/*',
          AppConstants.headerAuthorization: 'Bearer $accessToken',
          AppConstants.headerContentType: AppConstants.contentTypeJson,
        },
        body: json.encode({
          'show': show,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucess'] == true) {
          Logger.info('커서 설정 저장 성공: $show', 'SETTINGS');
          return true;
        } else {
          Logger.error('커서 설정 저장 실패: ${data['error']}', 'SETTINGS');
          return false;
        }
      } else {
        Logger.error('커서 설정 저장 실패: ${response.statusCode}', 'SETTINGS');
        return false;
      }
    } catch (error) {
      Logger.error('커서 설정 저장 오류', 'SETTINGS', error);
      return false;
    }
  }

  /// 서버에 모션 매핑 설정 저장
  /// leftClick, rightClick, paste (붙여넣기)는 UI 드롭다운 값 ('엄지와 검지를', '엄지와 중지를', '엄지와 약지를', '선택 안함')
  static Future<bool> saveMotionSettings({
    required String leftClick,    // 좌클릭 제스처 (motionLeftClick)
    required String rightClick,   // 우클릭 제스처 (motionRightClick) 
    required String paste,        // 붙여넣기 제스처 (motionWheelScroll)
  }) async {
    try {
      final accessToken = await AuthStorageService.getValidAccessToken();
      if (accessToken == null) {
        Logger.error('Access token이 없습니다', 'SETTINGS');
        return false;
      }

      // UI 값을 서버 모션 코드로 변환
      final motionLeftClick = GestureMapping.uiToMotionCode(leftClick);
      final motionRightClick = GestureMapping.uiToMotionCode(rightClick);
      final motionWheelScroll = GestureMapping.uiToMotionCode(paste);

      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.settingsMotion}'),
        headers: {
          AppConstants.headerAccept: '*/*',
          AppConstants.headerAuthorization: 'Bearer $accessToken',
          AppConstants.headerContentType: AppConstants.contentTypeJson,
        },
        body: json.encode({
          'motionLeftClick': motionLeftClick,
          'motionRightClick': motionRightClick,
          'motionWheelScroll': motionWheelScroll,  // 붙여넣기로 사용
          'motionRecordStart': AppConstants.motionUnassigned,
          'motionRecordStop': AppConstants.motionUnassigned,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucess'] == true) {
          Logger.info('모션 설정 저장 성공', 'SETTINGS');
          return true;
        } else {
          Logger.error('모션 설정 저장 실패: ${data['error']}', 'SETTINGS');
          return false;
        }
      } else {
        Logger.error('모션 설정 저장 실패: ${response.statusCode}', 'SETTINGS');
        return false;
      }
    } catch (error) {
      Logger.error('모션 설정 저장 오류', 'SETTINGS', error);
      return false;
    }
  }
}