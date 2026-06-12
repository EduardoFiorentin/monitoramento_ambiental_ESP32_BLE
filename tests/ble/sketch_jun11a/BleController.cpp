#include "BleController.h"

class CustomServerCallbacks : public NimBLEServerCallbacks {
private:
  bool* pDeviceConnected;

public:

  CustomServerCallbacks(bool* connectedFlag) : pDeviceConnected(connectedFlag) {}

  void onConnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo) override {
    *pDeviceConnected = true;
    Serial.println(">>> Cliente BLE conectado");
    Serial.print(" Endereço: ");
    Serial.println(connInfo.getAddress().toString().c_str());
  }

  void onDisconnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo, int reason) override {
    *pDeviceConnected = false;
    Serial.println(">>> Cliente BLE desconectado");
    pServer->startAdvertising();
  }
};

class CustomCharCallbacks : public NimBLECharacteristicCallbacks {
  void onRead(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo) override {
    Serial.println(" [Evento] Leitura da característica solicitada");
  }

  void onStatus(NimBLECharacteristic* pCharacteristic, int code) override {
    Serial.print(" [Evento] Status da notificação/indicação. Código:");
    Serial.println(code);
  }
};


BleController::BleController() {
  this->setup_callbacks();
}

void BleController::setup_callbacks() {
  this->customBLEServerCallback = new CustomServerCallbacks(&this->deviceConnected);
  this->customBLECharCallback = new CustomCharCallbacks();
}