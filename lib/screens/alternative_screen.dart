import 'package:flutter/material.dart';

const Color _kPrimaryGreenAlt = Color(0xFF1DB954);

class AlternativeScreen extends StatelessWidget {
  const AlternativeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Better Alternatives'),
        backgroundColor: _kPrimaryGreenAlt,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggested Better Alternatives',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: List.generate(
                  6,
                  (i) => Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _kPrimaryGreenAlt.withOpacity(0.12),
                        child: const Icon(Icons.eco, color: _kPrimaryGreenAlt),
                      ),
                      title: Text('Alternative Product ${i + 1}'),
                      subtitle: const Text(
                        'Eco-friendly, recyclable packaging',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryGreenAlt,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('View'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
