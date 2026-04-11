class LogSanitizer {
  static const Set<String> _sensitiveKeys = {
    'cookie',
    'authorization',
    'token',
    'api_key',
    'apikey',
    'password',
    'secret',
    'sessdata',
    'bili_jct',
    'subtitleonlineapikey',
    'subtitleonlineapikeyheader',
    'bilibilicookie',
    'webdavpassword',
  };

  static String sanitizeText(String input) {
    var sanitized = input;
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b(SESSDATA|bili_jct)=([^;\s]+)', caseSensitive: false),
      (match) => '${match.group(1)}=${_maskedToken(match.group(2) ?? "")}',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'\b(cookie|authorization)\s*[:=：]\s*([^\r\n]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}: ******',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'^(\s*(?:BilibiliCookie|SubtitleOnlineApiKey|SubtitleOnlineApiKeyHeader|WebDAVPassword|Authorization|Cookie|password|token|api[_ -]?key)\s*[：:]\s*)(.+)$',
        caseSensitive: false,
        multiLine: true,
      ),
      (match) => '${match.group(1)}******',
    );
    return sanitized;
  }

  static String describeStorageOperation(
    String action,
    dynamic key,
    dynamic value,
  ) {
    final normalizedKey = key?.toString() ?? '';
    final safeValue = sanitizeValueByKey(normalizedKey, value);
    return '$action：$normalizedKey\r\n$safeValue';
  }

  static String sanitizeValueByKey(String key, dynamic value) {
    if (_isSensitiveKey(key)) {
      return '******';
    }
    return sanitizeObject(value).toString();
  }

  static Map<String, dynamic> sanitizeHeaders(Map<String, dynamic> headers) {
    final result = <String, dynamic>{};
    headers.forEach((key, value) {
      if (_isSensitiveKey(key)) {
        result[key] = '******';
      } else {
        result[key] = sanitizeObject(value);
      }
    });
    return result;
  }

  static dynamic sanitizeObject(dynamic value, {String? parentKey}) {
    if (value is Map) {
      final result = <dynamic, dynamic>{};
      value.forEach((key, item) {
        final keyText = key?.toString() ?? '';
        if (_isSensitiveKey(keyText)) {
          result[key] = '******';
        } else {
          result[key] = sanitizeObject(item, parentKey: keyText);
        }
      });
      return result;
    }
    if (value is Iterable) {
      return value
          .map((item) => sanitizeObject(item, parentKey: parentKey))
          .toList();
    }
    if (value is String) {
      if (parentKey != null && _isSensitiveKey(parentKey)) {
        return '******';
      }
      return sanitizeText(value);
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final sensitiveKey in _sensitiveKeys) {
      final compare =
          sensitiveKey.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalized.contains(compare)) {
        return true;
      }
    }
    return false;
  }

  static String _maskedToken(String value) {
    if (value.isEmpty) {
      return '******';
    }
    if (value.length <= 8) {
      return '******';
    }
    return '${value.substring(0, 4)}******${value.substring(value.length - 4)}';
  }
}
