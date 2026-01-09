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
  final String nearbyCenter;
  final String tips;
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
    this.nearbyCenter = 'N/A',
    this.tips = 'N/A',
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
    String? nearbyCenter,
    String? tips,
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
      nearbyCenter: nearbyCenter ?? this.nearbyCenter,
      tips: tips ?? this.tips,
      ecoScore: ecoScore ?? this.ecoScore,
    );
  }

  // Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'productName': productName,
      'category': category,
      'ingredients': ingredients,
      'carbonFootprint': carbonFootprint,
      'packagingType': packagingType,
      'disposalMethod': disposalMethod,
      'containsMicroplastics': containsMicroplastics,
      'palmOilDerivative': palmOilDerivative,
      'crueltyFree': crueltyFree,
      'nearbyCenter': nearbyCenter,
      'tips': tips,
      'ecoScore': ecoScore,
    };
  }

  // Create from JSON
  factory ProductAnalysisData.fromJson(Map<String, dynamic> json) {
    return ProductAnalysisData(
      imageUrl: json['imageUrl'],
      productName: json['productName'] ?? 'N/A',
      category: json['category'] ?? 'N/A',
      ingredients: json['ingredients'] ?? 'N/A',
      carbonFootprint: json['carbonFootprint'] ?? 'N/A',
      packagingType: json['packagingType'] ?? 'N/A',
      disposalMethod: json['disposalMethod'] ?? 'N/A',
      containsMicroplastics: json['containsMicroplastics'] ?? false,
      palmOilDerivative: json['palmOilDerivative'] ?? false,
      crueltyFree: json['crueltyFree'] ?? false,
      nearbyCenter: json['nearbyCenter'] ?? 'N/A',
      tips: json['tips'] ?? 'N/A',
      ecoScore: json['ecoScore'] ?? 'N/A',
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
    String nearbyCenter = _extractValue(
      geminiOutput,
      r'Nearby Recycling Center\?:?\s*(.*?)\n',
    );
    String tips = _extractValue(geminiOutput, r'Eco Tips\?:?\s*(.*?)\n');
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
    nearbyCenter = _sanitizeField(nearbyCenter);
    tips = _sanitizeField(tips);

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
      nearbyCenter: nearbyCenter,
      tips: tips,
      ecoScore: ecoScore,
    );
  }

  /// Build from a structured Map (e.g. parsed JSON from Gemini).
  factory ProductAnalysisData.fromMap(
    Map<String, dynamic> m, {
    File? imageFile,
  }) {
    String readString(List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k].toString();
      }
      return 'N/A';
    }

    String productName = readString([
      'product_name',
      'name',
      'Product name',
      'productName',
      'product',
    ]);
    String category = readString([
      'category',
      'Category',
      'product_category',
      'productCategory',
    ]);
    String ingredients = readString([
      'ingredients',
      'Ingredients',
      'ingredient_list',
      'ingredientList',
      'ingredients_text',
      'ingredientsText',
    ]);
    String carbonFootprint = readString([
      'carbon_footprint',
      'carbonFootprint',
      'Carbon Footprint',
    ]);
    String packagingType = readString([
      'packaging_type',
      'packaging',
      'material',
      'Material',
    ]);
    String ecoScore = readString([
      'eco_score',
      'ecoScore',
      'Eco Score',
      'Eco-friendliness rating',
      'ecoscore',
      'ecoscore_grade',
    ]);

    // disposal steps may be array or string
    String disposalMethod = 'N/A';
    final ds =
        m['disposal_steps'] ??
        m['disposalSteps'] ??
        m['disposal_method'] ??
        m['How to Dispose'] ??
        m['How to Dispose?'];
    if (ds is List) {
      disposalMethod = ds
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .join('\n');
    } else if (ds != null) {
      disposalMethod = ds.toString();
    }

    // tips may be array or string
    String tips = 'N/A';
    final t = m['tips'] ?? m['eco_tips'] ?? m['Eco Tips'] ?? m['ecoTips'];
    if (t is List) {
      tips = t
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .join('\n');
    } else if (t != null) {
      tips = t.toString();
    }

    String nearbyCenter = readString([
      'nearby_center',
      'nearbyCenter',
      'Nearby Recycling Center',
    ]);

    bool microplastics = false;
    final mp = m['contains_microplastics'] ?? m['containsMicroplastics'];
    if (mp is bool) {
      microplastics = mp;
    } else if (mp is String)
      microplastics = mp.toLowerCase() == 'yes' || mp.toLowerCase() == 'true';

    bool palmOil = false;
    final po = m['palm_oil_derivative'] ?? m['palmOilDerivative'];
    if (po is bool) {
      palmOil = po;
    } else if (po is String)
      palmOil = po.toLowerCase() == 'yes' || po.toLowerCase() == 'true';

    bool crueltyFree = false;
    final cf = m['cruelty_free'] ?? m['crueltyFree'];
    if (cf is bool) {
      crueltyFree = cf;
    } else if (cf is String)
      crueltyFree = cf.toLowerCase() == 'yes' || cf.toLowerCase() == 'true';

    return ProductAnalysisData(
      imageFile: imageFile,
      productName: productName,
      category: category,
      ingredients: ingredients,
      carbonFootprint: carbonFootprint,
      packagingType: packagingType,
      disposalMethod: disposalMethod,
      containsMicroplastics: microplastics,
      palmOilDerivative: palmOil,
      crueltyFree: crueltyFree,
      nearbyCenter: nearbyCenter,
      tips: tips,
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
