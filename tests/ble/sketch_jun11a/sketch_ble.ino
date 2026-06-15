#include <Arduino.h>
#include "BleController.h"
#include <random>

BleController* bleController;

// Variáveis para controlo do tempo (Envio a cada 2000ms = 2 segundos)
unsigned long lastTransmissionTime = 0;
const unsigned long transmissionInterval = 2000; 
float temperaturaAtual = 25.4;
float humidadeAtual = 60.8;

void setup(){
  Serial.begin(115200);
  
  bleController = new BleController();
  bleController->begin();
}

void loop() {
  // Temporizador não-bloqueante
  if (millis() - lastTransmissionTime >= transmissionInterval) {
    lastTransmissionTime = millis();
    
    // Verifica se o utilizador está conectado antes de ler o sensor
    if (bleController->hasDeviceConnected()) {
      
      // LEITURA DO SENSOR

      float valor0_1 = random(0, 10000) / 10000.0;
      float resultado = (valor0_1 * 2.0) - 1.0;

      temperaturaAtual += resultado; 
      humidadeAtual += -resultado;
      // ------------------------------------------------
      
      // Envia os dados para a camada Bluetooth
      bleController->sendAmbientData(temperaturaAtual, humidadeAtual);

      // envia alterações na configuração (lock dos leds e unidade de medida dos graficos)
      bleController->sendConfigData(false, false);

      // envia qualquer alteração local nos atuadores para refletir no app
      bleController->sendLocalLedsState(true, true, true);
    }
  }
  
  bleController->processIndicators();
  // O loop fica livre para outras tarefas do sistema
}