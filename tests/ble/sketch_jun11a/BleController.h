#ifndef BLE_H
#define BLE_H

#include <NimBLEDevice.h>
#include <NimBLE2904.h>
#include <Arduino.h>


class BleController {
private:
  NimBLEServer* server = NULL;
  
  NimBLEServerCallbacks*            customBLEServerCallback = NULL;
  NimBLECharacteristicCallbacks*    customBLECharCallback = NULL;

  NimBLECharacteristic* dataCharacteristic = NULL;          // Valores atuais de temperatura e humidade
  NimBLECharacteristic* dataHystCharacteristic = NULL;      // Histórico dos últimos 60 minutos
  NimBLECharacteristic* ledsCharacteristic = NULL;          // leitura do estado atual dos leds e envio de comandos de controle
  NimBLECharacteristic* rgbLedCharacteristic = NULL;        // leitura do estado atual do led rgb e comando da cor 
  NimBLECharacteristic* rssiCharacteristic = NULL;          // intensidade do sinal
  NimBLECharacteristic* notifyCountCharacteristic = NULL;   // quantidade de notificações por minuto
  
  bool deviceConnected = false;
  int lastMinuteNotifyNum = 0;

  void setup_callbacks();


public: 
  BleController();
  void setup();
  bool hasDeviceConnected();


};

#endif


// static NimBLEServer* pServer = NULL;
// static NimBLECharacteristic* pTemperatureCharacteristic = NULL;
// static bool deviceConnected = false;
// static uint8_t temperatureValue = 25;  // 25°C