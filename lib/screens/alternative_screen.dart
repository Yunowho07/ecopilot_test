import 'package:flutter/material.dart';

class AlternativeScreen extends StatelessWidget {
  const AlternativeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Better Alternatives'),
        backgroundColor: const Color(0xFF1DB954),
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
                    child: ListTile(
                      leading: const Icon(Icons.eco, color: Colors.green),
                      title: Text('Alternative Product ${i + 1}'),
                      subtitle: const Text(
                        'Eco-friendly, recyclable packaging',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {},
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
