class FlutterNativeTimezone {
  /// Return a best-effort local timezone name. This shim is used to avoid
  /// requiring the native plugin during builds. It may return a non-IANA
  /// value on some platforms; callers should handle fallback to UTC.
  static Future<String> getLocalTimezone() async {
    try {
      return DateTime.now().timeZoneName;
    } catch (_) {
      return 'Etc/UTC';
    }
  }
}
