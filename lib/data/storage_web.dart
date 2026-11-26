import 'dart:js_interop';

@JS('window.localStorage')
external _Storage get _storage;
extension type _Storage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
}

class PlatformStorage {
  static const _key = 'apuntia.study.v1';
  Future<String?> read() async => _storage.getItem(_key);
  Future<void> write(String value) async => _storage.setItem(_key, value);
}
