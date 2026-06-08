import 'package:flutter/material.dart';
import 'screens/connection_screen.dart';

void main() {
  runApp(const TermometroApp());
}

class TermometroApp extends StatelessWidget {
  const TermometroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor BLE',
      debugShowCheckedModeBanner: false, // Remove a faixa de "DEBUG" do canto da tela
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // Diz ao app que a primeira tela a carregar é o Scanner
      home: const ConnectionScreen(), 
    );
  }
}