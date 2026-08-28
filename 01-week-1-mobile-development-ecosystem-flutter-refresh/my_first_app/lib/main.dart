import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, size: 72),
              SizedBox(height: 16),
              Text('Wawa Elent Irawanti', style: TextStyle(fontSize: 24)),
              Text('244107020192', style: TextStyle(fontSize: 20)),
              Text('Aku seorang model', style: TextStyle(fontSize: 50)),
              Text('Pemrograman Mobile — Minggu 1'),
            ],
          ),
        ),
      ),
    );
  }
}
