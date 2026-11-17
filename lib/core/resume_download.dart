import 'dart:typed_data';

import 'resume_download_stub.dart'
    if (dart.library.html) 'resume_download_web.dart' as platform;

Future<String?> saveResumeDownload(Uint8List bytes, String filename) =>
    platform.saveResumeDownload(bytes, filename);
