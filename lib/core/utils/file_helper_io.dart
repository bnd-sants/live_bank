import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileSaverImplementation {
  static Future<void> saveAndShare(Uint8List bytes, String fileName, {String? subject, String? text}) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        text: text,
        files: [XFile(file.path)],
      ),
    );
  }
}
