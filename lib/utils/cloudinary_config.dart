// Cloudinary configuration (reads from .env via flutter_dotenv)
//
// Security note: do NOT embed Cloudinary API secrets in the client app. Use
// an unsigned upload preset (configured in your Cloudinary dashboard) or
// perform signed uploads from a trusted server.
//
// Add the following to your project root `.env` file (example):
//
//   # Cloudinary unsigned upload preset
//   CLOUDINARY_CLOUD_NAME=your-cloud-name
//   CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
//
// Make sure your `.env` is loaded early in `main()` before widgets use it:
//
//   import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
//
//   Future<void> main() async {
//     await dotenv.load(fileName: '.env');
//     runApp(const MyApp());
//   }
//
// This file exposes getters that read the values from the loaded environment.
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get kCloudinaryCloudName =>
    dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim() ?? '';

String get kCloudinaryUploadPreset =>
    dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim() ?? '';

/// Returns true when both cloud name and unsigned preset are set to non-empty values.
bool get isCloudinaryConfigured {
  final c = kCloudinaryCloudName;
  final p = kCloudinaryUploadPreset;
  return c.isNotEmpty &&
      p.isNotEmpty &&
      c != 'dwxpph0wt' &&
      p != 'unsigned_upload';
}
