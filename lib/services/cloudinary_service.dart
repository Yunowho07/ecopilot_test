import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Minimal Cloudinary helper that uploads image bytes using an unsigned preset.
///
/// Usage:
///   final url = await CloudinaryService.uploadImageBytes(
///     bytes,
///     filename: 'scan.jpg',
///     cloudName: kCloudinaryCloudName,
///     uploadPreset: kCloudinaryUploadPreset,
///   );
///
/// IMPORTANT: Do NOT embed secret API keys in the app. Use an unsigned preset or server-side signed upload.
class CloudinaryService {
  /// Uploads raw image bytes to Cloudinary and returns the secure URL on success.
  /// Returns `null` on failure.
  static Future<String?> uploadImageBytes(
    Uint8List bytes, {
    required String filename,
    required String cloudName,
    required String uploadPreset,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      // Add any optional fields here (folder, context, tags, etc.)

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: null,
      );

      request.files.add(multipartFile);

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final Map<String, dynamic> jsonBody = json.decode(resp.body);
        return jsonBody['secure_url'] as String?;
      }

      return null;
    } catch (e) {
      // swallow and return null, caller can handle UI feedback
      return null;
    }
  }
}
