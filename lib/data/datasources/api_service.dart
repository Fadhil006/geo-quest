import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_config.dart';

/// Centralized HTTP client for the Spring Boot backend.
/// Uses custom JWT issued by POST /api/auth/google (NOT Firebase tokens).
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConfig.apiBaseUrl;
  final http.Client _client = http.Client();

  /// The JWT token issued by the backend after Google auth
  String? _jwt;

  /// The authenticated user's UID from the backend
  String? _uid;

  /// The authenticated user's email
  String? _email;

  /// Store auth data after login
  void setAuth({required String jwt, required String uid, required String email}) {
    _jwt = jwt;
    _uid = uid;
    _email = email;
  }

  /// Clear auth on logout
  void clearAuth() {
    _jwt = null;
    _uid = null;
    _email = null;
  }

  /// Whether we have a valid JWT stored
  bool get isAuthenticated => _jwt != null;

  String? get jwt => _jwt;
  String? get uid => _uid;
  String? get email => _email;

  /// Build headers with optional auth token
  Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth && _jwt != null) {
      headers['Authorization'] = 'Bearer $_jwt';
    }
    return headers;
  }

  /// GET request
  Future<dynamic> get(String path, {bool auth = true}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(auth: auth),
    );
    return _handleResponse(response);
  }

  /// POST request
  Future<dynamic> post(String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// DELETE request
  Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(auth: auth),
    );
    return _handleResponse(response);
  }

  /// Handle HTTP responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message = 'Request failed';
    try {
      final errorBody = jsonDecode(response.body);
      message = errorBody['message'] ?? errorBody['error'] ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }

    switch (response.statusCode) {
      case 400:
        throw ApiBadRequestException(message);
      case 401:
        throw ApiUnauthorizedException(message);
      case 403:
        throw ApiForbiddenException(message);
      case 404:
        throw ApiNotFoundException(message);
      case 429:
        throw ApiRateLimitException(message);
      default:
        throw ApiException(message, response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiBadRequestException extends ApiException {
  ApiBadRequestException(String message) : super(message, 400);
}

class ApiUnauthorizedException extends ApiException {
  ApiUnauthorizedException(String message) : super(message, 401);
}

class ApiForbiddenException extends ApiException {
  ApiForbiddenException(String message) : super(message, 403);
}

class ApiNotFoundException extends ApiException {
  ApiNotFoundException(String message) : super(message, 404);
}

class ApiRateLimitException extends ApiException {
  ApiRateLimitException(String message) : super(message, 429);
}
