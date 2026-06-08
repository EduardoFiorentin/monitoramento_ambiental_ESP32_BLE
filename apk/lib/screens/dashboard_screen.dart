import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DashboardScreen extends StatefulWidget {
  // O construtor exige receber o dispositivo que foi conectado no ecrã anterior
  final BluetoothDevice device;

  const DashboardScreen({super.key, required this.device});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  @override
  void initState() {
    super.initState();
    // Assim que o ecrã abre, iniciamos a descoberta dos serviços GATT
    descobrirServicos();
  }

  void descobrirServicos() async {
    try {
      // O widget.device acede à variável 'device' que está na classe de cima (StatefulWidget)
      List<BluetoothService> services = await widget.device.discoverServices();
      
      for (BluetoothService service in services) {
        debugPrint("Serviço encontrado: ${service.uuid}");
        // Aqui vamos mapear os UUIDs do seu enunciado (0x181A, etc.)
      }
    } catch (e) {
      debugPrint("Erro ao descobrir serviços: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.line_weight),
            onPressed: () async {
              // Botão para desconectar manualmente
              await widget.device.disconnect();
              if (mounted) Navigator.pop(context);
            },
          )
        ],
      ),
      body: const Center(
        child: Text('Painel de Controle e Gráficos em construção...'),
      ),
    );
  }
}