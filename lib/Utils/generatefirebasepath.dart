import 'package:path/path.dart' as p;

String generateFirebasePath(String folder, String originalFileName) {
  // Get current Firebase user UID or use 'public' if null

  // Sanitize filename (replace spaces, remove special chars, limit to 100 chars)
  String safeName(String name) {
    var sanitized = name.replaceAll(RegExp(r'\s+'), "_");
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), "");
    if (sanitized.length > 100) {
      sanitized = sanitized.substring(0, 100);
    }
    return sanitized;
  }

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = safeName(p.basename(originalFileName));

  return "$folder/$timestamp\_$fileName";
}
