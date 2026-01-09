import 'package:flutter/material.dart';
import 'package:ecopilot_test/models/product_analysis_data.dart';
import 'package:ecopilot_test/screens/alternative_screen.dart';

/// Wrapper screen that shows alternatives for a specific scanned product
class NewAlternativeScreen extends StatelessWidget {
  final ProductAnalysisData? scannedProduct;

  const NewAlternativeScreen({super.key, this.scannedProduct});

  @override
  Widget build(BuildContext context) {
    return AlternativeScreen(scannedProduct: scannedProduct);
  }
}
