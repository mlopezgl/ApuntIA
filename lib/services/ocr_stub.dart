class NoteScanner {
  bool get supported => false;
  Future<String?> scan({required bool camera}) async => throw UnsupportedError(
    'La captura está disponible en Android y iOS. Aquí puedes pegar tus apuntes.',
  );
  Future<String?> recover() async => null;
}
