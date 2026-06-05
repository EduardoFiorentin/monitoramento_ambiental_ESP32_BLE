import 'package:flutter/material.dart';

void main() {
  runApp(const MeuApp());
}

// 1. O Ponto de Entrada (Estático)
class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelaTemperatura(), // Chama a nossa tela principal
    );
  }
}

// 2. A Tela (Dinâmica - Precisa mudar quando o valor do sensor mudar)
class TelaTemperatura extends StatefulWidget {
  const TelaTemperatura({super.key});

  @override
  State<TelaTemperatura> createState() => _TelaTemperaturaState();
}

// 3. A Lógica da Tela
class _TelaTemperaturaState extends State<TelaTemperatura> {
  // Nossa variável de estado
  double temperatura = 22.0;

  // Função que simula a chegada de um novo dado do sensor
  void simularLeitura() {
    // O setState é a mágica: ele avisa o Flutter para redesenhar a tela
    setState(() {
      temperatura += 1.5; 
    });
  }

  @override
  Widget build(BuildContext context) {
    // O Scaffold monta a estrutura básica do app
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Sensor'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center( // Centraliza o conteúdo no meio da tela
        child: Column( // Empilha os widgets verticalmente
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Temperatura Atual:',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 10), // Cria um espaço vazio
            Text(
              '${temperatura.toStringAsFixed(1)} °C',
              style: const TextStyle(
                fontSize: 56, 
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
      // Um botão flutuante no canto da tela
      floatingActionButton: FloatingActionButton(
        onPressed: simularLeitura, // Chama a função ao clicar
        child: const Icon(Icons.add),
      ),
    );
  }
}