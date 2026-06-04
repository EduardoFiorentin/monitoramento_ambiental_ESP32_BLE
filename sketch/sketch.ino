#include "PulldownButton.h"
#include <LiquidCrystal_I2C.h>
#include "dht.h"
//define pin data


// #define pinDATA 18
#define DHTPIN 14     
#define DHTTYPE DHT22

// Globals
PulldownButton btn1(26), btn2(27);
LiquidCrystal_I2C lcd(0x27, 20, 4);
DHT dht(DHTPIN, DHTTYPE);             // CONTINUAR TESTANDO DHT


// Setup methods

void setup_lcd() {
  lcd.init();
  lcd.backlight();
}

void setup() {
  Serial.begin(115200);
  setup_lcd();
  // lcd.setCursor(3, 0);
  // lcd.print("Hello, world!");
  // lcd.setCursor(2, 1);
  // lcd.print("Ywrobot Arduino!");
  // lcd.setCursor(0, 2);
  // lcd.print("Arduino LCM IIC 2004");
  // lcd.setCursor(2, 3);
  // lcd.print("Power By Ec-yuan!");
  
  dht.begin();


}

void loop() {
  // Serial.println(digitalRead(26));
  // btn1.update();
  // btn2.update();

  // if (btn1.wasPressed()) {
  //   Serial.println("1");
  // }

  // if (btn2.wasPressed()) {
  //   Serial.println("2");
  // }
  

  delay(2000); // Essencial ter 2 segundos de pausa
  
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    Serial.println(F("Falha ao ler do sensor DHT!"));
    return;
  }

  Serial.print(F("Umidade: "));
  Serial.print(h);
  Serial.print(F("%  Temperatura: "));
  Serial.print(t);
  Serial.println(F("°C "));
}