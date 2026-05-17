import 'dart:typed_data';
import 'package:live_bank/core/utils/file_helper_stub.dart'
    if (dart.library.io) 'package:live_bank/core/utils/file_helper_io.dart'
    if (dart.library.html) 'package:live_bank/core/utils/file_helper_web.dart';

abstract class FileHelper {
  static Future<void> saveAndShare(Uint8List bytes, String fileName, {String? subject, String? text}) async {
    return FileSaverImplementation.saveAndShare(bytes, fileName, subject: subject, text: text);
  }
}
