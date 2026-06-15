
// final String uuidServicoControle = "d6ca719a-7ae1-485a-bf63-ac03fdf84527"; 
// final String uuidCharLedsSimples = "1384d4f8-05b5-4d0e-8d4b-ecfa8a2ee4eb";
// final String uuidCharLedRGB = "2214794a-21a9-4cb3-bc1d-d10aa147fad8";
// final String uuidCharDeviceConfig = "fc949d8b-c71e-4ee7-84a0-5c1fd772a999";


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
  // Estado dos Atuadores
  bool led1Ativo = false;
  bool led2Ativo = false;
  bool resetMinMaxAtivo = false;
  Color corSelecionada = Colors.blue;

  // bloqueio da placa - reflete nos controles
  bool isHardwareLocked = false; 

  final String uuidServicoControle = "d6ca719a-7ae1-485a-bf63-ac03fdf84527"; 
  final String uuidCharLedsSimples = "1384d4f8-05b5-4d0e-8d4b-ecfa8a2ee4eb";
  final String uuidCharLedRGB = "2214794a-21a9-4cb3-bc1d-d10aa147fad8";
  final String uuidCharDeviceConfig = "fc949d8b-c71e-4ee7-84a0-5c1fd772a999";


  BluetoothCharacteristic? charLedsSimples;
  BluetoothCharacteristic? charLedRGB;
  BluetoothCharacteristic? charDeviceConfig;

  // assinatura do estado de conexão da tela de controle
  StreamSubscription<List<int>>? _subLeds;
  StreamSubscription<List<int>>? _subConfig;
  StreamSubscription<BluetoothConnectionState>? _subEstadoConexao;

  @override
  void initState() {
    super.initState();
    mapearAtuadores();
  }

  @override
  void dispose() {
    _subLeds?.cancel();
    _subConfig?.cancel();
    _subEstadoConexao?.cancel(); // <-- Nova linha (evita vazamento de memória)
    super.dispose();
  }

  void mapearAtuadores() {
    // Escuta continuamente se o dispositivo reconectou para reatar os canais de escrita/notificação
    _subEstadoConexao = widget.device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        try {
          // 1. Limpa assinaturas antigas e inválidas se houver
          await _subLeds?.cancel();
          await _subConfig?.cancel();

          // 2. Força o redescoberta de serviços para limpar o cache do rádio
          List<BluetoothService> services = await widget.device.discoverServices();
          
          for (BluetoothService service in services) {
            if (service.uuid.toString().toLowerCase().contains(uuidServicoControle.toLowerCase())) {
              for (BluetoothCharacteristic characteristic in service.characteristics) {
                String charUuid = characteristic.uuid.toString().toLowerCase();
                
                // Mapeia e reativa a escuta dos LEDs Simples
                if (charUuid.contains(uuidCharLedsSimples.toLowerCase())) {
                  charLedsSimples = characteristic;
                  await characteristic.setNotifyValue(true);
                  
                  List<int> valorInicial = await characteristic.read();
                  atualizarLedsPeloHardware(valorInicial);

                  _subLeds = characteristic.onValueReceived.listen((bytes) {
                    atualizarLedsPeloHardware(bytes);
                  });
                } 
                
                // Mapeia o LED RGB
                else if (charUuid.contains(uuidCharLedRGB.toLowerCase())) {
                  charLedRGB = characteristic;
                }

                // Mapeia e reativa a escuta da Trava de Hardware
                else if (charUuid.contains(uuidCharDeviceConfig.toLowerCase())) {
                  charDeviceConfig = characteristic;
                  await characteristic.setNotifyValue(true);
                  
                  List<int> configInicial = await characteristic.read();
                  atualizarConfiguracao(configInicial);

                  _subConfig = characteristic.onValueReceived.listen((bytes) {
                    atualizarConfiguracao(bytes);
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Erro ao restabelecer canais de controle: $e");
        }
      }
    });
  }

  // decodifica byte de informações dos estados dos leds
  void atualizarLedsPeloHardware(List<int> bytes) {
    if (bytes.isEmpty) return;
    int payload = bytes.first;
    if (mounted) {
      setState(() {
        led1Ativo = (payload & 0x01) != 0;          // Bit 0
        led2Ativo = (payload & 0x02) != 0;          // Bit 1
        resetMinMaxAtivo = (payload & 0x04) != 0;   // Bit 2
      });
    }
  }

  // decodifica byte de configuração do dispositivo
  void atualizarConfiguracao(List<int> bytes) {
    if (bytes.isEmpty) return;
    int payload = bytes.first;
    if (mounted) {
      setState(() {
        // Bit 1: 0 = Liberado, 1 = Bloqueado
        isHardwareLocked = (payload & 0x02) != 0; 
      });
    }
  }

  // envia comando aos leds caso não haja bloqueio ativo
  void enviarComandoLeds() async {
    if (charLedsSimples == null || isHardwareLocked) return;
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

  // envia comando de cor ao rgb - caso não haja bloqueio
  void enviarCorRGB(Color cor) async {
    if (charLedRGB == null || isHardwareLocked) return;
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
        // AVISO VISUAL DE TRAVA DE HARDWARE
        if (isHardwareLocked)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade400),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Controle Bloqueado. O dispositivo está operando em Modo Local (Switch 1 ativo).",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Agrupamos os controles em um IgnorePointer. Se isHardwareLocked for true, 
        // ele bloqueia todos os cliques nos botões e sliders da tela.
        IgnorePointer(
          ignoring: isHardwareLocked,
          child: Opacity(
            opacity: isHardwareLocked ? 0.5 : 1.0, // Deixa a tela meio transparente se bloqueado
            child: Column(
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
                            
                            // Pequeno efeito pulso: desliga automaticamente após 1 segundo
                            if (val) {
                              Timer(const Duration(seconds: 1), () {
                                if (mounted) {
                                  setState(() { resetMinMaxAtivo = false; });
                                  enviarComandoLeds();
                                }
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
            ),
          ),
        ),
      ],
    );
  }
}