import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/log_sanitizer.dart';
import 'package:simple_live_core/simple_live_core.dart';

class CustomLogInterceptor extends Interceptor {
  bool _useVerboseLog(RequestOptions options) {
    return Log.verboseEnabled || options.extra['verboseLog'] == true;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra["ts"] = DateTime.now().millisecondsSinceEpoch;

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    var time =
        DateTime.now().millisecondsSinceEpoch - err.requestOptions.extra["ts"];
    if (!kReleaseMode) {
      Log.e('''【HTTP请求错误-${err.type}】 耗时:${time}ms
${err.message}

Request Method：${err.requestOptions.method}
Response Code：${err.response?.statusCode}
Request URL：${err.requestOptions.uri}
Request Query：${LogSanitizer.sanitizeObject(err.requestOptions.queryParameters)}
Request Data：${LogSanitizer.sanitizeObject(err.requestOptions.data)}
Request Headers：${LogSanitizer.sanitizeHeaders(err.requestOptions.headers)}
Response Headers：${LogSanitizer.sanitizeObject(err.response?.headers.map)}
Response Data：${LogSanitizer.sanitizeObject(err.response?.data)}''',
          err.stackTrace);
    } else {
      CoreLog.e('''[HTTP Error] [${err.type}] [Time:${time}ms]
${err.message}

Request Method：${err.requestOptions.method}
Response Code：${err.response?.statusCode}
Request URL：${err.requestOptions.uri}
Request Query：${LogSanitizer.sanitizeObject(err.requestOptions.queryParameters)}
Request Data：${LogSanitizer.sanitizeObject(err.requestOptions.data)}
Request Headers：${LogSanitizer.sanitizeHeaders(err.requestOptions.headers)}
Response Headers：${LogSanitizer.sanitizeObject(err.response?.headers.map)}
Response Data：${LogSanitizer.sanitizeObject(err.response?.data)}''',
          err.stackTrace);
    }

    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    var time = DateTime.now().millisecondsSinceEpoch -
        response.requestOptions.extra["ts"];
    if (!kReleaseMode && _useVerboseLog(response.requestOptions)) {
      Log.i(
        '''【HTTP请求响应】 耗时:${time}ms
Request Method：${response.requestOptions.method}
Request Code：${response.statusCode}
Request URL：${response.requestOptions.uri}
Request Query：${LogSanitizer.sanitizeObject(response.requestOptions.queryParameters)}
Request Data：${LogSanitizer.sanitizeObject(response.requestOptions.data)}
Request Headers：${LogSanitizer.sanitizeHeaders(response.requestOptions.headers)}
Response Headers：${LogSanitizer.sanitizeObject(response.headers.map)}
Response Data：${LogSanitizer.sanitizeObject(response.data)}''',
      );
    } else if (kReleaseMode) {
      CoreLog.i(
        "[HTTP Response] [time:${time}ms] [${response.statusCode}] ${response.requestOptions.uri}",
      );
    } else {
      Log.i(
        "[HTTP响应] [${response.requestOptions.method}] [${response.statusCode}] [${time}ms] ${response.requestOptions.uri}",
        false,
      );
    }
    super.onResponse(response, handler);
  }
}
