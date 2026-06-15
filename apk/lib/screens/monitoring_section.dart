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

  bool mostrarFahrenheit = false;

  List<FlSpot> historicoTempC = [];
  List<FlSpot> historicoTempF = [];
  List<FlSpot> historicoUmidade = [];
  double contadorTempo = 0;

  final String uuidServicoAmbiental = "181a";
  final String uuidServicoControle = "d6ca719a-7ae1-485a-bf63-ac03fdf84527"; 
  final String uuidCharDeviceConfig = "fc949d8b-c71e-4ee7-84a0-5c1fd772a999";

  StreamSubscription<List<int>>? _subNotificacao;
  StreamSubscription<List<int>>? _subConfig;
  StreamSubscription<BluetoothConnectionState>? _subEstadoConexao;

  @override
  void initState() {
    super.initState();
    escutarSensores();
  }

  @override
  void dispose() {
    _subNotificacao?.cancel();
    _subConfig?.cancel();
    _subEstadoConexao?.cancel();
    super.dispose();
  }

  void escutarSensores() {
    _subEstadoConexao = widget.device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        try {
          await _subNotificacao?.cancel();
          await _subConfig?.cancel();

          List<BluetoothService> services = await widget.device.discoverServices();
          
          for (BluetoothService service in services) {
            String serviceUuid = service.uuid.toString().toLowerCase();

            // temperatura e umidade
            if (serviceUuid.contains(uuidServicoAmbiental)) {
              for (BluetoothCharacteristic char in service.characteristics) {
                if (char.properties.notify) {
                  await char.setNotifyValue(true);
                  _subNotificacao = char.onValueReceived.listen((bytes) => desempacotarDados(bytes));
                }
              }
            }

            // controle - escuta o switch 4
            if (serviceUuid.contains(uuidServicoControle.toLowerCase())) {
              for (BluetoothCharacteristic char in service.characteristics) {
                if (char.uuid.toString().toLowerCase().contains(uuidCharDeviceConfig.toLowerCase())) {
                  await char.setNotifyValue(true);
                  
                  List<int> valorInicial = await char.read();
                  atualizarUnidade(valorInicial);

                  // configura para receber notificações notificações 
                  _subConfig = char.onValueReceived.listen((bytes) => atualizarUnidade(bytes));
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Erro no monitoramento: $e");
        } finally {
          if (mounted) setState(() { estaCarregando = false; });
        }
      }
    });
  }

  // coleta a unidade em que o grafico deve ser mostrado
  // byte 1 do payload
  void atualizarUnidade(List<int> bytes) {
    if (bytes.isEmpty) return;
    int payload = bytes.first;
    if (mounted) {
      setState(() {
        mostrarFahrenheit = (payload & 0x01) != 0; // Bit 0
      });
    }
  }

  // desempacotar dados de ambiente (temperatura e humidade)
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

      // Atualiza ambas as linhas do tempo
      historicoTempC.add(FlSpot(contadorTempo, tempCelsius));
      historicoTempF.add(FlSpot(contadorTempo, tempFahrenheit));
      historicoUmidade.add(FlSpot(contadorTempo, umidade));

      if (historicoTempC.length > 60) {
        historicoTempC.removeAt(0);
        historicoTempF.removeAt(0);
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
        
        construirCardGrafico(
          mostrarFahrenheit ? 'Histórico de Temperatura (°F)' : 'Histórico de Temperatura (°C)', 
          mostrarFahrenheit ? historicoTempF : historicoTempC, 
          Colors.orange
        ),
        
        construirCardGrafico('Histórico de Umidade', historicoUmidade, Colors.blue),
      ],
    );
  }
}