#include <Arduino.h>
#include "BleController.h"

BleController* bleController;

void setup(){
  Serial.begin(115200);
  
  // Instancia e inicializa o BLE apenas após o boot do sistema
  bleController = new BleController();
  bleController->begin();
}

void loop() {
  // Lógica principal
  delay(100);
}