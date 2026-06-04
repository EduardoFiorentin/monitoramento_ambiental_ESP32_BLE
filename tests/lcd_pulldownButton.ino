// Teste básico do LiquidCrystal_I2C
// Teste básico da classe de botões PulldownButton


#include "PulldownButton.h"
#include <LiquidCrystal_I2C.h>

// Globals
PulldownButton btn1(26), btn2(27);
LiquidCrystal_I2C lcd(0x27, 20, 4);


// Setup methods
void setup_lcd() {
  lcd.init();
  lcd.backlight();
}

void setup() {
  Serial.begin(115200);
  setup_lcd();
  lcd.setCursor(3, 0);
  lcd.print("Hello, world!");
  lcd.setCursor(2, 1);
  lcd.print("Ywrobot Arduino!");
  lcd.setCursor(0, 2);
  lcd.print("Arduino LCM IIC 2004");
  lcd.setCursor(2, 3);
  lcd.print("Power By Ec-yuan!");
}

void loop() {
  btn1.update();
  btn2.update();

  if (btn1.wasPressed()) {
    Serial.println("1");
  }

  if (btn2.wasPressed()) {
    Serial.println("2");
  }
}