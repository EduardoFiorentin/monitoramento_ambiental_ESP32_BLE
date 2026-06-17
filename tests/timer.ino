#include <Timer.h>

#define LED 2

void blinkLed() {
  digitalWrite(LED, !digitalRead(LED));
  Serial.println("LED Toggled!");
}


Timer ledTimer(500, blinkLed);

void setup() {
  Serial.begin(115200);
  pinMode(LED, OUTPUT);
  ledTimer.start();
}

void loop() {
  ledTimer.update();
}