import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genAi;

/// Small wrapper around the google_generative_ai package to provide a
/// simple generateResponse(prompt) function used by the scan enrichment step.
class GenerativeService {
  // Guard to signal availability (false if not initialized or missing key)
  static bool get isAvailable {
    // Don't access dotenv.env unless dotenv has been initialized; accessing
    // it too early throws NotInitializedError in web builds.
    if (!dotenv.isInitialized) return false;
    final key = dotenv.env['GOOGLE_API_KEY'];
    return key != null && key.isNotEmpty;
  }

  /// Generate a response from Gemini (via google_generative_ai). Returns an
  /// empty string on failure.
  static Future<String> generateResponse(String prompt) async {
    try {
      // Ensure dotenv is loaded (harmless if already loaded)
      if (!dotenv.isInitialized) await dotenv.load();

      final apiKey = dotenv.env['GOOGLE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return '';

      final content = [genAi.Content.text(prompt)];

      // Use Gemini 1.5 Flash - stable, fast, and reliable model with vision support
      final modelsToTry = ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'];
      for (final modelName in modelsToTry) {
        try {
          final model = genAi.GenerativeModel(model: modelName, apiKey: apiKey);
          final response = await model.generateContent(content);
          final text = response.text;
          if (text != null && text.isNotEmpty) return text;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('GenerativeService model "$modelName" failed: $e');
          }
          // If the API is not enabled, don't try other models.
          if (e.toString().contains('API has not been used')) {
            return '__API_DISABLED__';
          }
          // continue to next model
        }
      }

      return '';
    } catch (e) {
      if (kDebugMode) debugPrint('GenerativeService error: $e');
      // If the underlying library wasn't initialized, return a special marker
      // so the caller can avoid retrying other Gemini endpoints in this session.
      final s = e.toString();
      if (s.contains('NotInitialized') || s.contains('Not initialized')) {
        return '__NOT_INIT__';
      }
      return '';
    }
  }

  /// Lists available models and prints them to the debug console.
  static Future<void> listModels() async {
    if (!isAvailable) {
      if (kDebugMode) {
        debugPrint('Cannot list models, API key not available.');
      }
      return;
    }
    try {
      // Listing models via the client library is not implemented here to
      // avoid depending on package internals. If you need to inspect
      // available models, enable verbose logging or call the Cloud API
      // directly from a secure environment.
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error listing models: $e');
      }
    }
  }
}
