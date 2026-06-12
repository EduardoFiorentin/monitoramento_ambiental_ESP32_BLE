/*
 Código para Arduino IDE
 Bluetooth Low Energy - Servidor de Temperatura com NimBLE (versão 2.x)
 Funcionalidades:
 - Serviço customizado com uma característica de temperatura (leiturae notificação)
 - Atualização periódica da temperatura e envio de notificações
 */

#include <NimBLEDevice.h>
#include <NimBLE2904.h>

// ==================== DEFINIÇÕES DOS UUIDs ====================
#define SERVICE_UUID "ABF0"
#define CHARACTERISTIC_UUID "ABF1"

// ==================== VARIÁVEIS GLOBAIS ====================
static NimBLEServer* pServer = NULL;
static NimBLECharacteristic* pTemperatureCharacteristic = NULL;
static bool deviceConnected = false;
static uint8_t temperatureValue = 25;  // 25°C

// ==================== CALLBACKS DO SERVIDOR ====================
class MyServerCallbacks : public NimBLEServerCallbacks {
  // Chamado quando um cliente conecta (assinatura correta para NimBLE2.x)
  void onConnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo) override {
    deviceConnected = true;
    Serial.println(">>> Cliente BLE conectado");
    // Opcional: exibir o endereço MAC do cliente
    Serial.print(" Endereço: ");
    Serial.println(connInfo.getAddress().toString().c_str());
  }

  // Chamado quando um cliente desconecta (assinatura correta)
  void onDisconnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo, int reason) override {
    deviceConnected = false;
    Serial.println(">>> Cliente BLE desconectado");
    pServer->startAdvertising();  // Torna o dispositivo visível novamente
  }
};

// ==================== CALLBACKS DA CARACTERÍSTICA ====================
class MyCharCallbacks : public NimBLECharacteristicCallbacks {
  // Chamado quando o cliente realiza uma leitura da característica
  void onRead(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo) override {
    Serial.println(" [Evento] Leitura da característica solicitada");
    // O valor atual já está armazenado (setValue foi chamado).
    // A biblioteca automaticamente envia a resposta.
  }

  // Monitora o status de envio de notificações/indicações (substituto do antigo onNotify)
  void onStatus(NimBLECharacteristic* pCharacteristic, int code) override {
    Serial.print(" [Evento] Status da notificação/indicação. Código:");
    Serial.println(code);  // code == 0 significa sucesso Bluetooth em Sistemas Embarcados: Fundamentos, Protocolos e Aplicações 11
  }
};

// ==================== FUNÇÃO DE ATUALIZAÇÃO DA TEMPERATURA ====================
void updateTemperature() {
  // Simula leitura de sensor: incrementa de 1 em 1, limitando entre 20 e 50
  temperatureValue++;
  if (temperatureValue > 50) temperatureValue = 20;

  // Se houver um cliente conectado , envia notificação
  if (deviceConnected) {
    pTemperatureCharacteristic->notify(&temperatureValue, 1);  // 'true' para envio assíncrono
    Serial.print(" [Dado] Temperatura enviada: ");
    Serial.print(temperatureValue);
    Serial.println(" °C");
  }
}

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== Iniciando Servidor BLE com NimBLE (API 2.x) ===\n");

  // 1. Inicializa o dispositivo BLE com um nome
  NimBLEDevice ::init("ESP32_NimBLE_Temperature");
  Serial.println("[1] Dispositivo BLE inicializado. Nome: ESP32_NimBLE_Temperature");

  // 2. Cria o servidor e associa os callbacks de conexão
  pServer = NimBLEDevice ::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  Serial.println("[2] Servidor BLE criado e callbacks configurados");

  // 3. Cria o serviço
  NimBLEService* pService = pServer->createService(SERVICE_UUID);
  Serial.print("[3] Serviço criado com UUID: ");
  Serial.println(SERVICE_UUID);

  // 4. Cria a característica com propriedades READ e NOTIFY
  pTemperatureCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
  );

  // Cria um descritor para ser adicionado à caracteristica
  // Diz como os dados devem ser interpretados
  NimBLE2904* pFormat = new NimBLE2904();
  pFormat->setFormat(NimBLE2904 ::FORMAT_UINT8);
  pFormat->setNamespace(1);  // Bluetooth SIG Assigned Numbers
  pFormat->setUnit(0x272F);  // Unidade: grau Celsius (do assigned numbers)
  pFormat->setExponent(0);   // expoente = 10^0
  pFormat->setDescription(0);
  pTemperatureCharacteristic->addDescriptor(pFormat);

  //pTemperatureCharacteristic ->setValue(&temperatureValue , 1);
  pTemperatureCharacteristic->setCallbacks(new MyCharCallbacks());
  Serial.print("[4] Característica criada com UUID: ");
  Serial.println(CHARACTERISTIC_UUID);
  Serial.println(" Propriedades: READ | NOTIFY");

  // Nota: O descritor CCCD é adicionado automaticamente quando NOTIFY está presente.

  // 5. Inicia o serviço
  pService->start();
  Serial.println("[5] Serviço iniciado");

  // 6. Configura o advertising (tornar o dispositivo visível)
  // IMPORTANTE: setScanResponse(bool) foi substituído por setScanResponseData()
  NimBLEAdvertising* pAdvertising = NimBLEDevice ::getAdvertising();

  // Dados do pacote de advertising (broadcast principal)
  NimBLEAdvertisementData advData;
  advData.setName("ESP32_NimBLE_Temperature");
  advData.addServiceUUID(SERVICE_UUID);
  advData.setFlags(0x06);  // LE General Discoverable + BR/EDR não suportado

  // Dados de resposta a scan (scan response)
  NimBLEAdvertisementData scanRespData;
  scanRespData.setName("ESP32_NimBLE_Temperature");

  pAdvertising->setAdvertisementData(advData);
  pAdvertising->setScanResponseData(scanRespData);  // <--- substituto do setScanResponse(true)

  // Inicia o advertising
  pAdvertising->start();
  Serial.println("[6] Advertising iniciado. Dispositivo agora é visível.");

  Serial.println("\n=== Pronto! Aguardando conexão de cliente BLE ===\n");
}

// ==================== LOOP PRINCIPAL ====================
void loop() {
  if (deviceConnected) {
    updateTemperature();  // Atualiza e envia notificação a cada 2 segundos
    delay(2000);
  } else {
    delay(500);  // Sem conexão: apenas aguarda
  }
}