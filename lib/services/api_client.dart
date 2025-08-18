import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_storage_service.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class ApiClient {
  
  static Future<Map<String, String>> _getHeaders({
    String contentType = AppConstants.contentTypeJson,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      AppConstants.headerContentType: contentType,
    };
    
    if (includeAuth) {
      final validToken = await AuthStorageService.getValidAccessToken();
      if (validToken != null) {
        headers[AppConstants.headerAuthorization] = 'Bearer $validToken';
      }
    }
    
    return headers;
  }

  static Map<String, dynamic>? _parseResponse(http.Response response) {
    try {
      return json.decode(response.body);
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      ApiLogger.request('GET', endpoint);
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: headers,
      );

      ApiLogger.response(response.statusCode, endpoint);
      return _parseResponse(response);
    } catch (error) {
      ApiLogger.error('GET $endpoint failed', error);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String contentType = AppConstants.contentTypeJson,
    bool includeAuth = true,
  }) async {
    try {
      ApiLogger.request('POST', endpoint);
      final headers = await _getHeaders(
        contentType: contentType,
        includeAuth: includeAuth,
      );
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : '',
      );

      ApiLogger.response(response.statusCode, endpoint);
      return _parseResponse(response);
    } catch (error) {
      ApiLogger.error('POST $endpoint failed', error);
      return null;
    }
  }

  static Future<bool> uploadToS3(
    String presignedUrl,
    dynamic data, {
    String contentType = AppConstants.contentTypeImageJpeg,
  }) async {
    try {
      ApiLogger.request('PUT', 'S3_UPLOAD');
      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {AppConstants.headerContentType: contentType},
        body: data,
      );
      
      ApiLogger.response(response.statusCode, 'S3_UPLOAD');
      return response.statusCode == 200;
    } catch (error) {
      ApiLogger.error('S3 upload failed', error);
      return false;
    }
  }
}