import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'dashboard_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  // Lista que vai guardar os dispositivos encontrados
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  bool isConnecting = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  // Substitua pelo nome exato que o seu ESP32 vai anunciar
  final String targetDeviceName = "ESP32_NimBLE_Eduardo"; 

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
      // solicita as permissões de execução na tela do usuário
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // O Android exige localização ligada para escanear BLE
      ].request();

      // verifica se o usuário negou alguma permissão
      if (statuses[Permission.bluetoothScan]!.isDenied ||
          statuses[Permission.location]!.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões de Bluetooth e Localização são necessárias!')),
        );
        return;
      }

      // verifica se a antena Bluetooth do celular está ligada
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        // Tenta ligar o bluetooth automaticamente
        // se não funciona, avisa o usuário
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ligue o bluetooth!')),
          );
          return;
        }
      }

      // limpa resultados antigos e escaneia dispositivos
      setState(() {
        scanResults.clear();
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      
    } catch (e) {
      debugPrint("Erro ao escanear: $e");
    }
  }

  // função para parar a busca
  void onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Erro ao parar: $e");
    }
  }

  // Função de conexão versão Final (Produção)
  void onConnectPressed(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });
    
    await FlutterBluePlus.stopScan();
    
    try {
      // Abre a porta de comunicação 
      await device.connect(license: License.free, autoConnect: false);
      
      // Tenta fazer a autenticação de segurança
      try {
        await device.createBond();
      } catch (e) {
        // Se quebrar aqui, o usuário errou a senha ou apertou cancelar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha incorreta ou pareamento cancelado!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          setState(() { isConnecting = false; });
        }
        await device.disconnect();
        return;
      }
      
      // senha estava certa ou já estava salva
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conectado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // navega para o dashboard
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(device: device),
          ),
        ).then((_) {
          if (mounted) {
            setState(() { isConnecting = false; });
          }
        });
      }

    } catch (e) {
      // Se cair aqui, o erro foi antes da senha
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro físico de conexão: $e'),
            backgroundColor: Colors.red.shade900,
          ),
        );
        setState(() { isConnecting = false; });
      }
      await device.disconnect(); 
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
                      // Se isConnecting for true, o onPressed vira null (o que desativa o botão nativamente)
                      onPressed: isConnecting ? null : () => onConnectPressed(result.device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      // Troca o texto por um ícone de carregamento giratório
                      child: isConnecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blueAccent,
                              ),
                            )
                          : const Text('CONECTAR'),
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