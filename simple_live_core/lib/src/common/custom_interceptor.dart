import 'package:dio/dio.dart';

import 'core_log.dart';

class CustomInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra["ts"] = DateTime.now().millisecondsSinceEpoch;
    if (CoreLog.requestLogType == RequestLogType.all) {
      CoreLog.i(
        '''[HTTP Request] [${options.method}]
Request URL：${options.uri}
Request Query：${_sanitizeObject(options.queryParameters)}
Request Data：${_sanitizeObject(options.data)}
Request Headers：${_sanitizeHeaders(options.headers)}''',
      );
    } else if (CoreLog.requestLogType == RequestLogType.short) {
      CoreLog.i("[HTTP Request] [${options.method}] ${options.uri}");
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    var time =
        DateTime.now().millisecondsSinceEpoch - err.requestOptions.extra["ts"];
    if (CoreLog.requestLogType == RequestLogType.all) {
      CoreLog.e('''[HTTP Error] [${err.type}] [Time:${time}ms]
${err.message}

Request Method：${err.requestOptions.method}
Response Code：${err.response?.statusCode}
Request URL：${err.requestOptions.uri}
Request Query：${_sanitizeObject(err.requestOptions.queryParameters)}
Request Data：${_sanitizeObject(err.requestOptions.data)}
Request Headers：${_sanitizeHeaders(err.requestOptions.headers)}
Response Headers：${_sanitizeObject(err.response?.headers.map)}
Response Data：${_sanitizeObject(err.response?.data)}''', err.stackTrace);
    } else {
      CoreLog.e(
        "[HTTP Error] [${err.type}] [Time:${time}ms]\n[${err.response?.statusCode}] ${err.requestOptions.uri}",
        err.stackTrace,
      );
    }

    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    var time = DateTime.now().millisecondsSinceEpoch -
        response.requestOptions.extra["ts"];
    if (CoreLog.requestLogType == RequestLogType.all) {
      CoreLog.i(
        '''[HTTP Response] [time:${time}ms]
Request Method：${response.requestOptions.method}
Request Code：${response.statusCode}
Request URL：${response.requestOptions.uri}
Request Query：${_sanitizeObject(response.requestOptions.queryParameters)}
Request Data：${_sanitizeObject(response.requestOptions.data)}
Request Headers：${_sanitizeHeaders(response.requestOptions.headers)}
Response Headers：${_sanitizeObject(response.headers.map)}
Response Data：${_sanitizeObject(response.data)}''',
      );
    } else if (CoreLog.requestLogType == RequestLogType.short) {
      CoreLog.i(
        "[HTTP Response] [time:${time}ms] [${response.statusCode}] ${response.requestOptions.uri}",
      );
    }
    super.onResponse(response, handler);
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final result = <String, dynamic>{};
    headers.forEach((key, value) {
      final normalizedKey =
          key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (_isSensitiveKey(normalizedKey)) {
        result[key] = '******';
      } else {
        result[key] = _sanitizeObject(value);
      }
    });
    return result;
  }

  dynamic _sanitizeObject(dynamic value) {
    if (value is Map) {
      final result = <dynamic, dynamic>{};
      value.forEach((key, item) {
        final normalizedKey =
            key.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (_isSensitiveKey(normalizedKey)) {
          result[key] = '******';
        } else {
          result[key] = _sanitizeObject(item);
        }
      });
      return result;
    }
    if (value is Iterable) {
      return value.map(_sanitizeObject).toList();
    }
    if (value is String) {
      return value
          .replaceAllMapped(
            RegExp(r'\b(SESSDATA|bili_jct)=([^;\s]+)', caseSensitive: false),
            (match) => '${match.group(1)}=******',
          )
          .replaceAllMapped(
            RegExp(
              r'\b(cookie|authorization)\s*[:=：]\s*([^\r\n]+)',
              caseSensitive: false,
            ),
            (match) => '${match.group(1)}: ******',
          );
    }
    return value;
  }

  bool _isSensitiveKey(String key) {
    return key.contains('cookie') ||
        key.contains('authorization') ||
        key.contains('token') ||
        key.contains('apikey') ||
        key.contains('password') ||
        key.contains('secret');
  }
}
