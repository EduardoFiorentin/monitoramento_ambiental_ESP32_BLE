import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  // Lista que vai guardar os dispositivos encontrados
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  // Substitua pelo nome exato que o seu ESP32 vai anunciar
  final String targetDeviceName = "ESP32_SECURE_BLE_EDUARDO"; 

  @override
  void initState() {
    super.initState();
    // Nos "inscrevemos" para ouvir o resultado do scanner
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      // Filtramos para mostrar apenas o dispositivo com o nome do trabalho
      final filteredResults = results.where((r) => r.device.platformName == targetDeviceName).toList();
      setState(() {
        scanResults = filteredResults;
      });
    });

    // Monitora se o scanner está rodando ou parado
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      setState(() {
        isScanning = state;
      });
    });
  }

  @override
  void dispose() {
    // Sempre limpe os listeners quando a tela for fechada para não vazar memória
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  // Função que inicia a busca
  void onScanPressed() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint("Erro ao escanear: $e");
    }
  }

  // Função para parar a busca
  void onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Erro ao parar: $e");
    }
  }

  // Função de conexão com tratamento para o Passkey (MITM)
  void onConnectPressed(BluetoothDevice device) async {
    // Paramos de escanear ao tentar conectar
    await FlutterBluePlus.stopScan();
    
    try {
      // O FlutterBluePlus lida nativamente com o pareamento de segurança.
      // Quando chamamos o connect, o SO Android vai interceptar e exibir 
      // o pop-up pedindo os 6 dígitos se o ESP32 exigir MITM.
      await device.connect(license: License.free, autoConnect: false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conectado com sucesso!')),
      );
      
      // TODO: Navegar para o Painel de Monitoramento (Seção 2, 3 e 4)

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao conectar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner BLE'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: scanResults.isEmpty
          ? const Center(child: Text('Nenhum dispositivo encontrado. Pressione Escanear.'))
          : ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(result.device.platformName.isEmpty ? "Dispositivo Desconhecido" : result.device.platformName),
                    subtitle: Text('MAC: ${result.device.remoteId} \nSinal (RSSI): ${result.rssi} dBm'),
                    trailing: ElevatedButton(
                      onPressed: () => onConnectPressed(result.device),
                      child: const Text('CONECTAR'),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: isScanning ? onStopPressed : onScanPressed,
        backgroundColor: isScanning ? Colors.red : Colors.blueAccent,
        child: Icon(isScanning ? Icons.stop : Icons.search, color: Colors.white),
      ),
    );
  }
}