import 'dart:io';

class ProductAnalysisData {
  final File? imageFile;
  final String? imageUrl;
  final String productName;
  final String category;
  final String ingredients;
  final String carbonFootprint;
  final String packagingType;
  final String disposalMethod;
  final bool containsMicroplastics;
  final bool palmOilDerivative;
  final bool crueltyFree;
  final String ecoScore;

  ProductAnalysisData({
    this.imageFile,
    this.imageUrl,
    required this.productName,
    this.category = 'N/A',
    this.ingredients = 'N/A',
    this.carbonFootprint = 'N/A',
    this.packagingType = 'N/A',
    this.disposalMethod = 'N/A',
    this.containsMicroplastics = false,
    this.palmOilDerivative = false,
    this.crueltyFree = false,
    this.ecoScore = 'N/A',
  });

  ProductAnalysisData copyWith({
    File? imageFile,
    String? imageUrl,
    String? productName,
    String? category,
    String? ingredients,
    String? carbonFootprint,
    String? packagingType,
    String? disposalMethod,
    bool? containsMicroplastics,
    bool? palmOilDerivative,
    bool? crueltyFree,
    String? ecoScore,
  }) {
    return ProductAnalysisData(
      imageFile: imageFile ?? this.imageFile,
      imageUrl: imageUrl ?? this.imageUrl,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      carbonFootprint: carbonFootprint ?? this.carbonFootprint,
      packagingType: packagingType ?? this.packagingType,
      disposalMethod: disposalMethod ?? this.disposalMethod,
      containsMicroplastics:
          containsMicroplastics ?? this.containsMicroplastics,
      palmOilDerivative: palmOilDerivative ?? this.palmOilDerivative,
      crueltyFree: crueltyFree ?? this.crueltyFree,
      ecoScore: ecoScore ?? this.ecoScore,
    );
  }

  factory ProductAnalysisData.fromGeminiOutput(
    String geminiOutput, {
    File? imageFile,
  }) {
    String productName = _extractValue(
      geminiOutput,
      r'Product name:\s*(.*?)\n',
    );
    String category = _extractValue(geminiOutput, r'Category:\s*(.*?)\n');
    String ingredients = _extractValue(geminiOutput, r'Ingredients:\s*(.*?)\n');
    String carbonFootprint = _extractValue(
      geminiOutput,
      r'Carbon Footprint:\s*(.*?)\n',
    );
    String packagingType = _extractValue(
      geminiOutput,
      r'Packaging type:\s*(.*?)\n',
    );
    String disposalMethod = _extractValue(
      geminiOutput,
      r'Disposal method:\s*(.*?)\n',
    );
    String ecoScore = _extractValue(
      geminiOutput,
      r'Eco-friendliness rating:\s*(.*?)\n',
    );

    bool microplastics = _extractValue(
      geminiOutput,
      r'Contains microplastics\? \s*(.*?)\n',
    ).toLowerCase().contains('yes');
    bool palmOil = _extractValue(
      geminiOutput,
      r'Palm oil derivative\? \s*(.*?)\n',
    ).toLowerCase().contains('yes');
    bool crueltyFree = _extractValue(
      geminiOutput,
      r'Cruelty-Free\? \s*(.*?)\n',
    ).toLowerCase().contains('yes');

    if (category == 'N/A' && productName.toLowerCase().contains('cream')) {
      category = 'Personal Care (Sunscreen)';
    }

    String cleanIngredients = _sanitizeField(
      ingredients,
      removeIfContains: [
        productName,
        'Product name',
        'Category',
        'Eco-friendliness',
        'Carbon Footprint',
      ],
    );

    packagingType = _sanitizeField(packagingType);
    disposalMethod = _sanitizeField(disposalMethod);

    return ProductAnalysisData(
      imageFile: imageFile,
      productName: productName,
      category: category,
      ingredients: cleanIngredients,
      carbonFootprint: carbonFootprint,
      packagingType: packagingType,
      disposalMethod: disposalMethod,
      containsMicroplastics: microplastics,
      palmOilDerivative: palmOil,
      crueltyFree: crueltyFree,
      ecoScore: ecoScore,
    );
  }

  static String _sanitizeField(String raw, {List<String>? removeIfContains}) {
    if (raw.trim().isEmpty) return 'N/A';
    final lines = raw
        .split(RegExp(r"\r?\n"))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final seen = <String>{};
    final out = <String>[];
    for (var line in lines) {
      var skip = false;
      if (removeIfContains != null) {
        for (var sub in removeIfContains) {
          if (sub.isEmpty) continue;
          if (line.toLowerCase().contains(sub.toLowerCase())) {
            skip = true;
            break;
          }
        }
      }
      if (skip) continue;

      if (seen.contains(line)) continue;

      if (line.toUpperCase() == 'N/A') continue;

      seen.add(line);
      out.add(line);
    }

    if (out.isEmpty) return 'N/A';
    return out.join('\n');
  }

  static String _extractValue(String text, String regexPattern) {
    final RegExp regExp = RegExp(regexPattern, dotAll: true);
    final Match? match = regExp.firstMatch(text);
    String? rawValue = match?.group(1)?.trim();
    if (rawValue != null) {
      final noteIndex = rawValue.indexOf('(');
      if (noteIndex > 0) {
        rawValue = rawValue.substring(0, noteIndex).trim();
      }
    }
    return rawValue ?? 'N/A';
  }
}
