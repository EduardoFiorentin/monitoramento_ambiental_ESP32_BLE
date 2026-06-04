#include <Arduino.h>
#include "RGBLed.h"

// Pinos: (R, G, B, Com)
RGBLed myLed(17, 16, 4);

void setup() {
  // Instanciação já cuidou de todo o setup do PWM!
}

void loop() {
  // Fica Vermelho
  myLed.setColor(255, 0, 0);
  delay(1000);

  // Fica Verde usando método individual
  myLed.clear(); // Apaga tudo
  myLed.setGreen(255);
  delay(1000);

  // Fica Roxo (Mistura)
  myLed.setColor(128, 0, 128);
  delay(1000);
}