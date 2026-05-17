import 'dart:typed_data';

class FileSaverImplementation {
  static Future<void> saveAndShare(Uint8List bytes, String fileName, {String? subject, String? text}) async {
    throw UnsupportedError('Cannot save file without dart:io or dart:html');
  }
}
