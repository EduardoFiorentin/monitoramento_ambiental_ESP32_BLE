import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'monitoring_section.dart'; 
import 'control_section.dart';    
import 'connection_metrics_section.dart';

class DashboardScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DashboardScreen({super.key, required this.device});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  // flags do ciclo de vida da conexão
  bool _desconexaoIntencional = false;
  bool _jaEstavaConectado = false; 
  bool _podeSair = false;
  StreamSubscription<BluetoothConnectionState>? _estadoConexaoSub;

  final List<String> _titulos = [
    "Monitoramento Ambiental",
    "Painel de Controle Atuadores",
    "Métricas de Conexão",
  ];

  @override
  void initState() {
    super.initState();
    monitorarEstadoConexao();
  }

  @override
  void dispose() {
    _estadoConexaoSub?.cancel();
    super.dispose();
  }

  // tratamento de queda de conexão
  void monitorarEstadoConexao() {
    _estadoConexaoSub = widget.device.connectionState.listen((BluetoothConnectionState state) async {
      
      if (state == BluetoothConnectionState.connected) {
        // Se voltou de uma queda (não é a primeira abertura da tela - não precisa senha)
        if (_jaEstavaConectado && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Remove a barra vermelha
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conexão reativada!'), 
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        _jaEstavaConectado = true;
      } 
      
      else if (state == BluetoothConnectionState.disconnected) {
        if (!_desconexaoIntencional) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars(); 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ESP32 Desconectado. Tentando reconectar...'), 
                backgroundColor: Colors.red,
                duration: Duration(days: 1), 
              ),
            );
          }
          
          while (!_desconexaoIntencional && widget.device.isDisconnected) {
            try {
              await widget.device.connect(license: License.free, autoConnect: false);
              break; 
            } catch (e) {
              if (_desconexaoIntencional) break; 
              await Future.delayed(const Duration(seconds: 2)); 
            }
          }
        }
      }
    });
  }

  void realizarDesconexaoSegura() {
    setState(() {
      _podeSair = true;
      _desconexaoIntencional = true;
    });

    // destrói absolutamente todas as barras de notificação pendentes
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars(); 
    }

    // manda o comando de desconectar rodar solto em segundo plano, 
    // sem o "await", para não travar a interface do usuário.
    widget.device.disconnect().catchError((e) {
      debugPrint("Tentativa de desconexão em background: $e");
    });

    // volta imediatamente para a tela inicial do aplicativo
    if (mounted) {
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> abas = [
      MonitoringSection(device: widget.device),
      ControlSection(device: widget.device),
      ConnectionMetricsSection(device: widget.device),
    ];

    // O PopScope "sequestra" a ação do botão físico de voltar do telemóvel
    return PopScope(
      canPop: _podeSair,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        realizarDesconexaoSegura(); // limpa caches antes de fechar 
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titulos[_currentIndex]),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: realizarDesconexaoSegura,
            )
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: abas,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Monitorar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune),
              label: 'Controlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wifi_tethering),
              label: 'Sinal',
            ),
          ],
        ),
      ),
    );
  }
}