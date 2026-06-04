#include "RGBLed.h"

RGBLed::RGBLed(int redPin, int greenPin, int bluePin) {
  this->pinR = redPin;
  this->pinG = greenPin;
  this->pinB = bluePin;
  // this->pinCommon = commonPin;

  // Configuração do pino Comum (Cátodo Comum = Negativo)
  // pinMode(this->pinCommon, OUTPUT);
  // digitalWrite(this->pinCommon, LOW);

  setupPWM(this->pinR);
  setupPWM(this->pinG);
  setupPWM(this->pinB);
}

void RGBLed::setupPWM(int pin) {
  ledcAttach(pin, 5000, 8);
  ledcWrite(pin, 0); 
}

void RGBLed::setRed(int value) {
  ledcWrite(this->pinR, constrain(value, 0, 255));
}

void RGBLed::setGreen(int value) {
  ledcWrite(this->pinG, constrain(value, 0, 255));
}

void RGBLed::setBlue(int value) {
  ledcWrite(this->pinB, constrain(value, 0, 255));
}

void RGBLed::setColor(int r, int g, int b) {
  setRed(r);
  setGreen(g);
  setBlue(b);
}

void RGBLed::clear() {
  setRed(RGB_LOW);
  setGreen(RGB_LOW);
  setBlue(RGB_LOW);
}