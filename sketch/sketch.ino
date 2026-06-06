#include "DHT_Async.h"
#include <LiquidCrystal_I2C.h>
#include "PulldownButton.h"
#include "RGBLed.h"
#include "SwitchPullDown.h"

static const int DHT_SENSOR_PIN = 14;

#define   DHT_SENSOR_TYPE   DHT_TYPE_22
#define   PIN_BUTTON_1      26
#define   PIN_BUTTON_2      27
#define   PIN_SW_1          34
#define   PIN_SW_2          35
#define   PIN_SW_3          32
#define   PIN_SW_4          33
#define   PIN_LED_1         2
#define   PIN_LED_2         15

// Outputs 
DHT_Async             dht_sensor(DHT_SENSOR_PIN, DHT_SENSOR_TYPE);
RGBLed                rgbLed(17, 16, 4);
LiquidCrystal_I2C     lcd(0x27, 20, 4);

// Inputs
PulldownButton 
  btn1(PIN_BUTTON_1),   // alternância manual das telas do LCD 
  btn2(PIN_BUTTON_2);   // reset minimos e máximos

SwitchPullDown 
  sw1(PIN_SW_1),    // Bloqueia/Libera o controle dos LEDs pelo smartphone (Controle Local vs. Remoto); 
  sw2(PIN_SW_2),    // Ligam/Desligam os led localmente (mudança deve ser refletida no APP);
  sw3(PIN_SW_3),    // Ligam/Desligam os led localmente (mudança deve ser refletida no APP);
  sw4(PIN_SW_4);    // Define a visualização do gráfico no APP entre graus C e F.



// State variables ---------------------------------------------------------------- 
enum LCDState {
  SCREEN_1_TEMP_C,    // temp graus C + Hum %
  SCREEN_2_TEMP_F,    // temp graus F + Hum %
  SCREEN_3_TEMP_HIST, // minimo e máximo de temperatura desde a inicialização
  SCREEN_4_HUM_HIST,  // minimo e máximo de umidade desde a inicialização
  SCREEN_5_BLE        // estado BLE
};

// SETUP METHODS ------------------------------------------------------------------
void setup_lcd() {
  lcd.init();
  lcd.backlight();
}


// UPDATE METHODS ----------------------------------------------------------------
void update_buttons() {
  sw1.update();
  sw2.update();
  sw3.update();
  sw4.update();
  btn1.update();
  btn2.update();
}


// CONTROLL METHODS -------------------------------------------------------------

void setup() {

}

void loop() {

}