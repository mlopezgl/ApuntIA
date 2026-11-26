import 'package:flutter/services.dart';

class PlatformStorage {
  static const _channel = MethodChannel('com.axiomanetwork.apuntia/storage');
  Future<String?> read() => _channel.invokeMethod<String>('read');
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', {'value': value});
}
