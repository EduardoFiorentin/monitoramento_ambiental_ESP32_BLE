#include "BleController.h"

class CustomServerCallbacks : public NimBLEServerCallbacks {
private:
  bool* pDeviceConnected;

public:
  CustomServerCallbacks(bool* connectedFlag) : pDeviceConnected(connectedFlag) {}

  void onConnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo) override {
    *pDeviceConnected = true;
    Serial.println(">>> Cliente BLE conectado");
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
    Serial.print(" [Evento] Status. Código:");
    Serial.println(code);
  }
};

BleController::BleController() {
  // Construtor agora não inicializa hardware. Fica vazio ou inicializa variáveis simples.
}

void BleController::begin() {
  // 1. Inicializa o rádio Bluetooth
  NimBLEDevice::init(BLE_NAME_ADVERTISING);

  this->customBLEServerCallback = new CustomServerCallbacks(&this->deviceConnected);
  this->customBLECharCallback = new CustomCharCallbacks();
  this->server = NimBLEDevice::createServer();
  this->server->setCallbacks(this->customBLEServerCallback);

  // 2. Cria os serviços
  this->envMonitoringService = this->server->createService(BLE_SERVICE_UID_ENV_MONITORING);
  this->actuatorControllService = this->server->createService(BLE_SERVICE_UID_ACTUATOR_CONTROLL);
  this->connectIndicatorService = this->server->createService(BLE_SERVICE_UID_CONNECT_INDICATOR);

  // 3. Cria as características e ASSOCIA aos ponteiros da classe
  this->dataCharacteristic = this->envMonitoringService->createCharacteristic(
    BLE_CHAR_UID_ACTUAL_DATA, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
  );
  this->dataHystCharacteristic = this->envMonitoringService->createCharacteristic(
    BLE_CHAR_UID_HYST_GRAPHIC, NIMBLE_PROPERTY::READ
  );

  this->ledsCharacteristic = this->actuatorControllService->createCharacteristic(
    BLE_CHAR_UID_SIMPLE_LEDS, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE
  );
  this->rgbLedCharacteristic = this->actuatorControllService->createCharacteristic(
    BLE_CHAR_UID_RGB_LED, NIMBLE_PROPERTY::WRITE_NR
  );
  
  this->rssiCharacteristic = this->connectIndicatorService->createCharacteristic(
    BLE_CHAR_UID_RSSI, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
  );
  this->notifyCountCharacteristic = this->connectIndicatorService->createCharacteristic(
    BLE_CHAR_UID_NOTIFY_COUNT, NIMBLE_PROPERTY::READ
  );

  // Associa o callback às características que podem ser escritas ou lidas
  this->ledsCharacteristic->setCallbacks(this->customBLECharCallback);

  // 4. INICIA os serviços
  this->envMonitoringService->start();
  this->actuatorControllService->start();
  this->connectIndicatorService->start();

  // 5. Configura e inicia o Advertiser
// 5. Configura e inicia o Advertiser
  this->pAdvertising = NimBLEDevice::getAdvertising();
  
  // Dados do pacote de advertising (broadcast principal)
  NimBLEAdvertisementData advData;
  advData.setFlags(0x06);  // LE General Discoverable + BR/EDR não suportado
  
  // Vamos usar o UUID de 16-bits (181A) aqui porque ocupa pouquíssimo espaço (2 bytes)
  advData.addServiceUUID(BLE_SERVICE_UID_ENV_MONITORING); 
  
  // Resposta de Scan (Scan Response) - Entregue apenas se o celular pedir mais detalhes
  NimBLEAdvertisementData scanRespData;
  scanRespData.setName(BLE_NAME_ADVERTISING); 
  
  // Opcional: Se quiser que o celular veja o serviço de atuadores antes de conectar
  scanRespData.addServiceUUID(BLE_SERVICE_UID_ACTUATOR_CONTROLL); 

  // Aplica os pacotes configurados ao Advertiser
  this->pAdvertising->setAdvertisementData(advData);
  this->pAdvertising->setScanResponseData(scanRespData);
  
  // Inicia a transmissão
  this->pAdvertising->start();

  Serial.println("BLE Iniciado e aguardando conexões...");
}

bool BleController::hasDeviceConnected() {
  return this->deviceConnected;
}