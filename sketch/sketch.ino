#include "DHT_Async.h"
#include <LiquidCrystal_I2C.h>
#include "PulldownButton.h"
#include "RGBLed.h"
#include "SwitchPullDown.h"
#include "BleController.h"
#include "Timer.h"
#include "SimpleLed.h"

#define   DHT_SENSOR_PIN    18
#define   DHT_SENSOR_TYPE   DHT_TYPE_22
#define   DHT_MEASURE_TIME  4000ul

#define   BLE_DATA_TRANSMISSION_INTERVAL                  1000
#define   BLE_RSSI_TRANSMISSION_INTERVAL                  5000

#define   PIN_BUTTON_1      26
#define   PIN_BUTTON_2      27
#define   PIN_SW_1          34
#define   PIN_SW_2          35
#define   PIN_SW_3          32
#define   PIN_SW_4          33
#define   PIN_LED_1         2
#define   PIN_LED_2         15
#define   PIN_LED_RGB_R     17
#define   PIN_LED_RGB_G     16
#define   PIN_LED_RGB_B     4

#define   MSG_TEMP_C        "Temp (C): "      // lcd screen 1 
#define   MSG_TEMP_F        "Temp (F): "      // lcd screen 1
#define   MSG_HUM           "Hum (%): "       // lcd screen 1
#define   MSG_TEMP_MIN      "Temp min: "      // lcd screen 2
#define   MSG_TEMP_MAX      "Temp max: "      // lcd screen 2
#define   MSG_HUM_MIN       "Hum min: "       // lcd screen 3
#define   MSG_HUM_MAX       "Hum max: "       // lcd screen 3
#define   MSG_BLE_STTS      "BLE Status: "    // lcd screen 4
#define   MSG_BLE_CONN      "Conectado"
#define   MSG_BLE_ADV       "Anunciando"
#define   MSG_BLE_DISC      "Desconectado"

#define CELSIUS_TO_FAHRENHEIT(c) (((c) * 9.0) / 5.0 + 32.0)


#define DHT_READ_MOCK     // Comentar para usar sensor nas leituras 
// #define IS_WOKWI          // Comentar para usar classe de bluetooth

void update_min_max();
void update_lcd_messages();
void envDataTransmissionCallback();
void rssiTransmissionCallback();
void notificationWindowCallback();


// ENUM =============================================================
enum LCDStateEnum {
  SCREEN_1_TEMP_C,      // temp graus C + Hum %
  SCREEN_2_TEMP_F,      // temp graus F + Hum %
  SCREEN_3_TEMP_HIST,   // minimo e máximo de temperatura desde a inicialização
  SCREEN_4_HUM_HIST,    // minimo e máximo de umidade desde a inicialização
  SCREEN_5_BLE,         // estado BLE
  SCREEN_6_PAIR_CODE    // Apresenta o codigo em tela quando em modo de anúncio
};


// Outputs 
DHT_Async             *dht_sensor;
BleController         *bleController;
RGBLed                rgbLed(PIN_LED_RGB_R, PIN_LED_RGB_G, PIN_LED_RGB_B);
SimpleLed             led1(PIN_LED_1), led2(PIN_LED_2);
LiquidCrystal_I2C     lcd(0x27, 16, 2);

// Inputs
PulldownButton 
  btn1(PIN_BUTTON_1),   // alternância manual das telas do LCD 
  btn2(PIN_BUTTON_2);   // reset minimos e máximos

SwitchPullDown 
  sw1(PIN_SW_1),        // Bloqueia/Libera o controle dos LEDs pelo smartphone (Controle Local vs. Remoto); 
  sw2(PIN_SW_2),        // Ligam/Desligam os led localmente (mudança deve ser refletida no APP);
  sw3(PIN_SW_3),        // Ligam/Desligam os led localmente (mudança deve ser refletida no APP);
  sw4(PIN_SW_4);        // Define a visualização do gráfico no APP entre graus C e F.



// State variables ===================================================================
LCDStateEnum lcdState = SCREEN_1_TEMP_C;

Timer 
  notificationWindowTimer               (1000, notificationWindowCallback),
  envDataTransmitionTimer               (BLE_DATA_TRANSMISSION_INTERVAL, envDataTransmissionCallback), 
  rssiTransmitionTimer                  (BLE_RSSI_TRANSMISSION_INTERVAL, rssiTransmissionCallback);



// Value variables    ================================================================
float temp = 0.0, minTemp = 40.0, maxTemp = 0.0;
float hum = 0.0, minHum = 40.0, maxHum = 0.0;

// Flag variables ===============================================================
bool isLedsBlockedToApp = false;



// TODO Rever chamadas aos métodos que enviam informações 
// Todos eles já tratam internamente se o dispositivo está conectado - não é necessário if

// TODO No apk - ao reconectar esp, enviar os comandos de led para atualizar o estado inicial 





// CALLBACKS DE ATUALIZAÇÃO DOS DADOS VINDOS DO BLE  =======================================
void processAppLedsCommandCallback(bool appLed1, bool appLed2, bool appReset) {
  if (isLedsBlockedToApp) {
    Serial.println("Comando do APP ignorado: Controle bloqueado fisicamente (SW1).");
    return;
  }

  if (appLed1) led1.setOn(); 
  else led1.setOff();
  
  if (appLed2) led2.setOn(); 
  else led2.setOff();

  if (appReset) {
    Serial.println("Reset dos valores min/max acionado pelo APP.");
    setup_min_max();
    update_lcd_messages();
  }
}

void processAppRgbCommandCallback(uint8_t r, uint8_t g, uint8_t b) {
  if (isLedsBlockedToApp) {
    return;
  }
  
  rgbLed.setColor(r, g, b);
}

void envDataTransmissionCallback() {
  if (bleController != nullptr) {
    bleController->sendAmbientData(temp, hum);
  }
}

void rssiTransmissionCallback() {
  if (bleController != nullptr) {
    bleController->notifyRssi();
  }
}

// Serve para manter a janela de contagem de notificações circulando, mesmo que não hajam interações
void notificationWindowCallback() {
  if (bleController != nullptr) {
    bleController->updateNotificationWindow();
  }
}

// SETUP METHODS ================================================================
void setup_lcd() {
  lcd.init();
  lcd.backlight();
}

void setup_min_max() {
  maxTemp = temp;
  minTemp = temp;
  maxHum = hum;
  minHum = hum;
}

void setup_ble() {
#ifndef IS_WOKWI
  bleController = new BleController();
  bleController->begin();
#else
  Serial.println("Inicialização do BLE ignorada. Wokwi detectado!");
#endif
}

void setup_dht() {
  #ifndef DHT_READ_MOCK
  dht_sensor = new DHT_Async(DHT_SENSOR_PIN, DHT_SENSOR_TYPE);
  #endif
}

void setup_io() {
  btn1.begin();
  btn2.begin();
  
  sw1.begin();
  sw2.begin();
  sw3.begin();
  sw4.begin();

  rgbLed.begin();
  led1.begin();
  led2.begin();
}


// LCD CONTROLL =================================================================
void write_lcd_row_1(String text) {
  lcd.setCursor(0, 0);
  lcd.print("                ");
  lcd.setCursor(0, 0);
  lcd.print(text);
}

void write_lcd_row_2(String text) {
  lcd.setCursor(0, 1);
  lcd.print("                ");
  lcd.setCursor(0, 1);
  lcd.print(text);
}

void set_next_lcd_state() {
  switch (lcdState) {
    case SCREEN_1_TEMP_C:
      lcdState = SCREEN_2_TEMP_F;
      break;

    case SCREEN_2_TEMP_F:
      lcdState = SCREEN_3_TEMP_HIST;
      break;

    case SCREEN_3_TEMP_HIST:
      lcdState = SCREEN_4_HUM_HIST;
      break;

    case SCREEN_4_HUM_HIST:
      lcdState = SCREEN_5_BLE;
      break;

    case SCREEN_5_BLE:
      lcdState = SCREEN_1_TEMP_C;
      break;

    default:
      break;
  }
}

void update_lcd_messages() {
  if ( lcdState == SCREEN_1_TEMP_C) {
    String msgTempC= MSG_TEMP_C + String(temp);
    String msgHum= MSG_HUM + String(hum);
    write_lcd_row_1(msgTempC);
    write_lcd_row_2(msgHum);
  }

  else if ( lcdState == SCREEN_2_TEMP_F) {
    String msgTempF= MSG_TEMP_F + String(CELSIUS_TO_FAHRENHEIT(temp));
    String msgHum= MSG_HUM + String(hum);
    write_lcd_row_1(msgTempF);
    write_lcd_row_2(msgHum);
  }

  else if ( lcdState == SCREEN_3_TEMP_HIST) {
    String msgMinTempC= MSG_TEMP_MIN + String(minTemp) + " C"; 
    String msgMaxTempC= MSG_TEMP_MAX + String(maxTemp) + " %";
    write_lcd_row_1(msgMaxTempC);
    write_lcd_row_2(msgMinTempC);
  }

  else if ( lcdState == SCREEN_4_HUM_HIST) {
    String msgMaxHum= MSG_HUM_MAX + String(maxHum) + " %";
    String msgMinHum= MSG_HUM_MIN + String(minHum) + " %"; 
    write_lcd_row_1(msgMaxHum);
    write_lcd_row_2(msgMinHum);
  }

  else if ( lcdState == SCREEN_5_BLE) {
    write_lcd_row_1(MSG_BLE_STTS);
    write_lcd_row_2(MSG_BLE_CONN);
  }
  else {
    write_lcd_row_1("ERRO!");
    write_lcd_row_2("Unkn. State");
  }
  
}

// DHT MEASURE CONTROLL ===========================================================
static bool measure_environment(float *temperature, float *humidity) {
  static unsigned long measurement_timestamp = millis();
  if (millis() - measurement_timestamp > DHT_MEASURE_TIME) {
    
    #ifndef DHT_READ_MOCK
    if (dht_sensor->measure(temperature, humidity)) {
      measurement_timestamp = millis();
      update_min_max();
      update_lcd_messages();
      return (true);
    }
    #else
    float valor0_1 = random(0, 10000) / 10000.0;
    float resultado = (valor0_1 * 2.0) - 1.0;

    *temperature += resultado; 
    *humidity += -resultado;
    measurement_timestamp = millis();
    update_min_max();
    update_lcd_messages();
    return (true);
    #endif
  }
  return (false);
}


// STATES CONTROLL =================================================================
void update_hardware_state() {
  if (btn1.wasPressed()) {
    set_next_lcd_state();
    update_lcd_messages();
  }

  if (btn2.wasPressed()) {
    maxTemp = temp;
    minTemp = temp;
    maxHum = hum;
    minHum = hum;
    update_lcd_messages();
  }

  // Controle de bloqueio do hardware
  if (sw1.hasChanged()) {
    // switch foi ligado
    if (sw1.isOn()) {
      // No ato do bloqueio: 
      //  leds assumem imediatamente o estado das chaves
      //  estado refletido para o app (independente do que estava antes no app)
      
      isLedsBlockedToApp = true;
      Serial.println("Controle local ativado. App bloqueado");

      // leds assumem o estado das chaves 
      if (sw2.isOn()) led1.setOn();
      else led1.setOff();  
      if (sw3.isOn()) led2.setOn();
      else led2.setOff();
      
      // novo estado replicado para o apk
      if (bleController->hasDeviceConnected() && bleController != nullptr){ 
        bleController->sendConfigData(isLedsBlockedToApp, sw4.isOn());
        bleController->sendLocalLedsState(led1.isOn(), led2.isOn(), false);
      }
    }
    // switch foi desligado
    else {
      isLedsBlockedToApp = false;
      Serial.println("Controle local desativado. App liberado");
      if (bleController->hasDeviceConnected() && bleController != nullptr){ 
        bleController->sendConfigData(isLedsBlockedToApp, sw4.isOn());
      }
    }
  }

  if (sw2.hasChanged()) {
    if (isLedsBlockedToApp) {
      if (sw2.isOn() && !led1.isOn()) {
        Serial.println("Ligando led 1");
        led1.setOn();
      }
      if (!sw2.isOn() && led1.isOn()) {
        Serial.println("Desligando led 1");
        led1.setOff();
      }

      // envia alteração para dispositivo
      if (bleController->hasDeviceConnected() && bleController != nullptr){ 
        bleController->sendLocalLedsState(led1.isOn(), led2.isOn(), false);
      }
    }
  }

  if (sw3.hasChanged()) {
    if (isLedsBlockedToApp) {
      if (sw3.isOn() && !led2.isOn()) {
        Serial.println("Ligando led 1");
        led2.setOn();
      }
      if (!sw3.isOn() && led2.isOn()) {
        Serial.println("Desligando led 1");
        led2.setOff();
      }
      // envia alteração para dispositivo
      if (bleController->hasDeviceConnected() && bleController != nullptr){ 
        bleController->sendLocalLedsState(led1.isOn(), led2.isOn(), false);
      }
    }
  }
  
  if (sw4.hasChanged()) {
    if (bleController->hasDeviceConnected() && bleController != nullptr){ 
      bleController->sendConfigData(isLedsBlockedToApp, sw4.isOn());
    }
  }
}

void update_io() {
  sw1.update();
  sw2.update();
  sw3.update();
  sw4.update();
  btn1.update();
  btn2.update();
}

void update_dht_measures() {
  if (measure_environment(&temp, &hum)) {
    // TODO Ver se envio temp e hum a cada leitura ou a cada x ms
  }
}

void update_min_max() {
  if (temp < minTemp) {
    minTemp = temp;
  }
  if (temp > maxTemp) {
    maxTemp = temp;
  }
  if (hum < minHum) {
    minHum = hum;
  }
  if (hum > maxHum) {
    maxHum = hum;
  }
}

void setup() {
  Serial.begin(115200);
  setup_lcd();
  setup_ble();
  setup_io();
  setup_dht();
  update_lcd_messages();
  if (bleController != nullptr) {
    bleController->setLedsCallback(processAppLedsCommandCallback);
    bleController->setRgbCallback(processAppRgbCommandCallback);
  }
  envDataTransmitionTimer.start();
  rssiTransmitionTimer.start();
  notificationWindowTimer.start();
  // notificationsCountTransmitionTimer.start();
}

void loop() {

  // estados 
  update_io();
  update_dht_measures();
  update_hardware_state();
  
  // timers
  envDataTransmitionTimer.update();
  rssiTransmitionTimer.update();
  notificationWindowTimer.update();
  // notificationsCountTransmitionTimer.update();
}





