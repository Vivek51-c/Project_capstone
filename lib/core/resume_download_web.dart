import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<String?> saveResumeDownload(Uint8List bytes, String filename) async {
  final blob = html.Blob(
    [bytes],
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  final link = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(link);
  link.click();
  link.remove();
  Future<void>.delayed(const Duration(seconds: 1), () => html.Url.revokeObjectUrl(url));
  return null;
}
