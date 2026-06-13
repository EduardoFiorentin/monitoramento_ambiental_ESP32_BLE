import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';

class ConnectionMetricsSection extends StatefulWidget {
  final BluetoothDevice device;
  const ConnectionMetricsSection({super.key, required this.device});

  @override
  State<ConnectionMetricsSection> createState() => _ConnectionMetricsSectionState();
}

class _ConnectionMetricsSectionState extends State<ConnectionMetricsSection> {
  bool estaCarregando = true;
  int rssiAtual = 0;
  int contadorNotificacoes = 0;

  List<FlSpot> historicoRssi = [];
  double contadorTempo = 0;

  final String uuidServicoIndicadores = "e01c7a1d-8c40-428c-ba7b-a7f7980120b8";
  final String uuidCharRssi = "fe4e82d1-ea3e-43af-a72d-9b7622a8113c";
  final String uuidCharContador = "9ecd2413-1a5e-490a-993c-da9f6f1259f9";

  BluetoothCharacteristic? charRssi;
  BluetoothCharacteristic? charContador;
  
  StreamSubscription<List<int>>? _assinaturaRssi;
  StreamSubscription<BluetoothConnectionState>? _assinaturaEstadoConexao; // <-- Adicionado
  Timer? _timerLeituraContador;

  @override
  void initState() {
    super.initState();
    mapearIndicadores();
  }

  @override
  void dispose() {
    _assinaturaRssi?.cancel();
    _assinaturaEstadoConexao?.cancel(); // <-- Adicionado
    _timerLeituraContador?.cancel();
    super.dispose();
  }

  void mapearIndicadores() {
    // Escuta as reconexões para remapear os ponteiros das características
    _assinaturaEstadoConexao = widget.device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        try {
          await _assinaturaRssi?.cancel();
          _timerLeituraContador?.cancel(); // Para o timer antigo se houver

          List<BluetoothService> services = await widget.device.discoverServices();
          for (BluetoothService service in services) {
            if (service.uuid.toString().toLowerCase().contains(uuidServicoIndicadores.toLowerCase())) {
              for (BluetoothCharacteristic characteristic in service.characteristics) {
                String charUuid = characteristic.uuid.toString().toLowerCase();

                if (charUuid.contains(uuidCharRssi.toLowerCase())) {
                  charRssi = characteristic;
                  if (characteristic.properties.notify) {
                    await characteristic.setNotifyValue(true);
                    _assinaturaRssi = characteristic.onValueReceived.listen((bytes) {
                      processarRssi(bytes);
                    });
                  }
                }

                if (charUuid.contains(uuidCharContador.toLowerCase())) {
                  charContador = characteristic;
                }
              }
            }
          }

          // Reinicia o laço de leitura periódica do contador
          if (charContador != null) {
            _timerLeituraContador = Timer.periodic(const Duration(seconds: 2), (timer) {
              lerContador();
            });
          }
        } catch (e) {
          debugPrint("Erro ao remapear métricas: $e");
        } finally {
          if (mounted) setState(() { estaCarregando = false; });
        }
      }
    });
  }

  // Função para tratar o dado de RSSI (-dBm) recebido via Notify
  void processarRssi(List<int> bytes) {
    if (bytes.isEmpty) return;

    // RSSI é recebido como int8 (inteiro com sinal de 8 bits). 
    // Como o Dart lê os bytes como uint8 padrão (0-255), fazemos a conversão manual:
    int valorRssi = bytes.first > 127 ? bytes.first - 256 : bytes.first;

    setState(() {
      rssiAtual = valorRssi;
      contadorTempo++;
      historicoRssi.add(FlSpot(contadorTempo, rssiAtual.toDouble()));

      // Mantém apenas os últimos 60 pontos no gráfico
      if (historicoRssi.length > 60) {
        historicoRssi.removeAt(0);
      }
    });
  }

  // Função disparada pelo Timer para solicitar ativamente a leitura (Read)
  void lerContador() async {
    if (charContador == null || widget.device.isDisconnected) return;
    try {
      List<int> bytes = await charContador!.read();
      if (bytes.isNotEmpty) {
        // Assume que o C++ está enviando o contador como um uint16 (2 bytes)
        int valor = 0;
        if (bytes.length >= 2) {
          Uint8List buffer = Uint8List.fromList(bytes);
          ByteData byteData = ByteData.sublistView(buffer);
          valor = byteData.getUint16(0, Endian.little);
        } else {
          valor = bytes.first; // Fallback caso envie apenas 1 byte
        }
        
        if (mounted) setState(() { contadorNotificacoes = valor; });
      }
    } catch (e) {
      debugPrint("Erro ao ler contador: $e");
    }
  }

  Widget construirGraficoRssi() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Intensidade do Sinal (RSSI)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: historicoRssi.isEmpty
                  ? const Center(child: Text("Aguardando sinal..."))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                        lineBarsData: [
                          LineChartBarData(
                            spots: historicoRssi,
                            isCurved: true,
                            color: Colors.purpleAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: Colors.purpleAccent.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (estaCarregando) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.signal_cellular_alt, color: Colors.purple, size: 32),
                      const SizedBox(height: 8),
                      Text('$rssiAtual dBm', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple)),
                      const Text('Sinal Atual', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.teal, size: 32),
                      const SizedBox(height: 8),
                      Text('$contadorNotificacoes', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal)),
                      const Text('Notificações (60s)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        construirGraficoRssi(),
      ],
    );
  }
}