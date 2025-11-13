import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  bool _fetching = false;
  Map<String, dynamic>? _product;

  Future<void> _fetchProduct(String barcode) async {
    setState(() {
      _fetching = true;
    });
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if ((data['status'] ?? 0) == 1) {
          final product = data['product'] as Map<String, dynamic>;
          _product = {
            'product_name':
                product['product_name'] ?? product['generic_name'] ?? '',
            'category': (product['categories_tags'] as List?)?.join(', ') ?? '',
            'ingredients': product['ingredients_text'] ?? '',
            'packaging': product['packaging'] ?? '',
            'image_url':
                product['image_front_small_url'] ?? product['image_url'] ?? '',
            'analysis': 'Lookup from OpenFoodFacts for barcode $barcode',
            'raw_api': product,
          };
        } else {
          _product = {'error': 'Product not found'};
        }
      } else {
        _product = {'error': 'HTTP ${resp.statusCode}'};
      }
    } catch (e) {
      _product = {'error': e.toString()};
    } finally {
      setState(() {
        _fetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: const Color(0xFF1DB954),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) async {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final raw = barcodes.first.rawValue;
                      if (raw != null && !_fetching) {
                        await _fetchProduct(raw);
                      }
                    }
                  },
                ),
                if (_fetching)
                  const Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_product != null) ...[
                  if (_product!['error'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Error: ${_product!['error']}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else ...[
                    if ((_product!['image_url'] as String).isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: Image.network(
                          _product!['image_url'] as String,
                          fit: BoxFit.contain,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _product!['product_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Category: ${_product!['category'] ?? ''}'),
                    const SizedBox(height: 6),
                    Text(
                      'Ingredients: ${_product!['ingredients'] ?? ''}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_product);
                      },
                      child: const Text('Use this product'),
                    ),
                  ],
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Enter barcode manually',
                        ),
                        onSubmitted: (val) async {
                          if (val.trim().isEmpty) return;
                          await _fetchProduct(val.trim());
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
