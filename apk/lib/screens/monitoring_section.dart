import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';

class MonitoringSection extends StatefulWidget {
  final BluetoothDevice device;
  const MonitoringSection({super.key, required this.device});

  @override
  State<MonitoringSection> createState() => _MonitoringSectionState();
}
class _MonitoringSectionState extends State<MonitoringSection> {
  double tempCelsius = 0.0;
  double tempFahrenheit = 0.0;
  double umidade = 0.0;
  bool estaCarregando = true;

  List<FlSpot> historicoTemperatura = [];
  List<FlSpot> historicoUmidade = [];
  double contadorTempo = 0;

  final String uuidServicoAmbiental = "181a";
  
  // Duas assinaturas: uma para os sensores e outra para monitorar o status do hardware
  StreamSubscription<List<int>>? _assinaturaNotificacao;
  StreamSubscription<BluetoothConnectionState>? _assinaturaEstadoConexao;

  @override
  void initState() {
    super.initState();
    escutarSensores();
  }

  @override
  void dispose() {
    _assinaturaNotificacao?.cancel();
    _assinaturaEstadoConexao?.cancel(); // Cancela o monitor de estado
    super.dispose();
  }

  void escutarSensores() {
    // Escuta continuamente o estado da conexão diretamente nesta aba
    _assinaturaEstadoConexao = widget.device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        try {
          
          // necessário para não travar a visualização dos dados: 
          // se já existia uma assinatura antiga pendente da queda, cancela ela
          await _assinaturaNotificacao?.cancel();

          // redescobre os serviços para atualizar o cache do hardware
          List<BluetoothService> services = await widget.device.discoverServices();
          
          for (BluetoothService service in services) {
            if (service.uuid.toString().toLowerCase().contains(uuidServicoAmbiental)) {
              for (BluetoothCharacteristic characteristic in service.characteristics) {
                if (characteristic.properties.notify) {
                  // 3. Reativa o descritor de notificação no ESP32
                  await characteristic.setNotifyValue(true);
                  
                  // 4. Cria o novo cano de dados reativo
                  _assinaturaNotificacao = characteristic.onValueReceived.listen((List<int> bytes) {
                    desempacotarDados(bytes);
                  });
                  break;
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Erro ao restabelecer fluxo de dados: $e");
        } finally {
          if (mounted) setState(() { estaCarregando = false; });
        }
      }
    });
  }

  void desempacotarDados(List<int> bytes) {
    if (bytes.length < 6) return;
    Uint8List buffer = Uint8List.fromList(bytes);
    ByteData byteData = ByteData.sublistView(buffer);

    int rawCelsius = byteData.getInt16(0, Endian.little);
    int rawFahrenheit = byteData.getInt16(2, Endian.little);
    int rawHumidity = byteData.getUint16(4, Endian.little);

    setState(() {
      tempCelsius = rawCelsius / 100.0;
      tempFahrenheit = rawFahrenheit / 100.0;
      umidade = rawHumidity / 100.0;
      contadorTempo++;

      historicoTemperatura.add(FlSpot(contadorTempo, tempCelsius));
      historicoUmidade.add(FlSpot(contadorTempo, umidade));

      if (historicoTemperatura.length > 60) {
        historicoTemperatura.removeAt(0);
        historicoUmidade.removeAt(0);
      }
    });
  }

  Widget construirCardGrafico(String titulo, List<FlSpot> pontos, Color corLinha) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: pontos.isEmpty
                  ? const Center(child: Text("Aguardando dados..."))
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
                            spots: pontos,
                            isCurved: true,
                            color: corLinha,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: corLinha.withOpacity(0.1)),
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
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text('${tempCelsius.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      Text('${tempFahrenheit.toStringAsFixed(1)} °F', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text('${umidade.toStringAsFixed(1)} %', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const Text('Umidade', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        construirCardGrafico('Histórico de Temperatura', historicoTemperatura, Colors.orange),
        construirCardGrafico('Histórico de Umidade', historicoUmidade, Colors.blue),
      ],
    );
  }
}