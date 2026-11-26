import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class NoteScanner {
  final _picker = ImagePicker();
  static const _channel = MethodChannel('com.axiomanetwork.apuntia/ocr');
  bool get supported => Platform.isAndroid || Platform.isIOS;
  Future<String?> scan({required bool camera}) async {
    if (!supported) {
      throw UnsupportedError('La captura requiere Android o iOS.');
    }
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2600,
      imageQuality: 95,
      requestFullMetadata: false,
    );
    return file == null ? null : _recognize(file);
  }

  Future<String?> recover() async {
    if (!Platform.isAndroid) return null;
    final result = await _picker.retrieveLostData();
    if (result.exception != null) throw result.exception!;
    return result.files?.isNotEmpty == true
        ? _recognize(result.files!.first)
        : null;
  }

  Future<String> _recognize(XFile file) async {
    final result = await _channel.invokeMethod<String>('recognize', {
      'path': file.path,
    });
    if (result == null || result.trim().isEmpty) {
      throw const FormatException(
        'No encontré texto. Acércate, mejora la luz o pega tus apuntes.',
      );
    }
    return result;
  }
}
