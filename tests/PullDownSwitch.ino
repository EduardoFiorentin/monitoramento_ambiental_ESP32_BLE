// teste da classe SwitchPullDown aplicada aos switchs do projeto 

#include <Arduino.h>
#include "SwitchPullDown.h"

SwitchPullDown sw1(34), sw2(35), sw3(32), sw4(33);

void setup() {
  Serial.begin(115200);
}

void loop() {
  sw1.update();
  sw2.update();
  sw3.update();
  sw4.update();

  Serial.print(sw1.isOn());
  Serial.print(" ");
  Serial.print(sw2.isOn());
  Serial.print(" ");
  Serial.print(sw3.isOn());
  Serial.print(" ");
  Serial.println(sw4.isOn());
  

  if (sw1.hasChanged()) {
    Serial.print("O switch 1 mudou! Estado atual: ");
    if (sw1.isOn()) {
      Serial.println("LIGADO");
    } else {
      Serial.println("DESLIGADO");
    }
    delay(1000);
  }
  if (sw2.hasChanged()) {
    Serial.print("O switch 2 mudou! Estado atual: ");
    if (sw2.isOn()) {
      Serial.println("LIGADO");
    } else {
      Serial.println("DESLIGADO");
    }
    delay(1000);
  }
  if (sw3.hasChanged()) {
    Serial.print("O switch 3 mudou! Estado atual: ");
    if (sw3.isOn()) {
      Serial.println("LIGADO");
    } else {
      Serial.println("DESLIGADO");
    }
    delay(1000);
  }
  if (sw4.hasChanged()) {
    Serial.print("O switch 4 mudou! Estado atual: ");
    if (sw4.isOn()) {
      Serial.println("LIGADO");
    } else {
      Serial.println("DESLIGADO");
    }
    delay(1000);
  }
  
}