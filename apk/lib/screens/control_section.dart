import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:async';

class ControlSection extends StatefulWidget {
  final BluetoothDevice device;
  const ControlSection({super.key, required this.device});

  @override
  State<ControlSection> createState() => _ControlSectionState();
}

class _ControlSectionState extends State<ControlSection> {
  bool led1Ativo = false;
  bool led2Ativo = false;
  bool resetMinMaxAtivo = false;
  Color corSelecionada = Colors.blue;

  final String uuidServicoControle =    "d6ca719a-7ae1-485a-bf63-ac03fdf84527"; 
  final String uuidCharLedsSimples =    "1384d4f8-05b5-4d0e-8d4b-ecfa8a2ee4eb";
  final String uuidCharLedRGB =         "2214794a-21a9-4cb3-bc1d-d10aa147fad8";

  BluetoothCharacteristic? charLedsSimples;
  BluetoothCharacteristic? charLedRGB;

  @override
  void initState() {
    super.initState();
    mapearAtuadores();
  }

  void mapearAtuadores() async {
    try {
      List<BluetoothService> services = await widget.device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase().contains(uuidServicoControle)) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();
            if (charUuid.contains(uuidCharLedsSimples)) {
              charLedsSimples = characteristic;
            } else if (charUuid.contains(uuidCharLedRGB)) {
              charLedRGB = characteristic;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao mapear controle: $e");
    }
  }

  void enviarComandoLeds() async {
    if (charLedsSimples == null) return;
    int payload = 0;
    if (led1Ativo) payload |= 0x01;
    if (led2Ativo) payload |= 0x02;
    if (resetMinMaxAtivo) payload |= 0x04;

    try {
      await charLedsSimples!.write([payload], allowLongWrite: false);
    } catch (e) {
      debugPrint("Erro ao enviar comando dos LEDs: $e");
    }
  }

  void enviarCorRGB(Color cor) async {
    if (charLedRGB == null) return;
    try {
      await charLedRGB!.write([cor.red, cor.green, cor.blue], withoutResponse: true);
    } catch (e) {
      debugPrint("Erro ao enviar RGB: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("LED Vermelho Simples"),
                  secondary: const Icon(Icons.lightbulb, color: Colors.red),
                  value: led1Ativo,
                  onChanged: (val) {
                    setState(() { led1Ativo = val; });
                    enviarComandoLeds();
                  },
                ),
                SwitchListTile(
                  title: const Text("LED Verde Simples"),
                  secondary: const Icon(Icons.lightbulb, color: Colors.green),
                  value: led2Ativo,
                  onChanged: (val) {
                    setState(() { led2Ativo = val; });
                    enviarComandoLeds();
                  },
                ),
                SwitchListTile(
                  title: const Text("Resetar Valores Mín/Máx"),
                  secondary: const Icon(Icons.refresh, color: Colors.grey),
                  value: resetMinMaxAtivo,
                  onChanged: (val) {
                    setState(() { resetMinMaxAtivo = val; });
                    enviarComandoLeds();
                    if (val) {
                      Timer(const Duration(seconds: 1), () {
                        setState(() { resetMinMaxAtivo = false; });
                        enviarComandoLeds();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.color_lens, color: Colors.purple),
                    SizedBox(width: 8),
                    Text("Controle do LED RGB", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ColorPicker(
                  pickerColor: corSelecionada,
                  onColorChanged: (Color cor) {
                    setState(() { corSelecionada = cor; });
                    enviarCorRGB(cor);
                  },
                  pickerAreaHeightPercent: 0.4,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsv,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}