#ifndef RGB_LED_H
#define RGB_LED_H

#include <Arduino.h>

#define RGB_LOW 0

class RGBLed {
private:
  int pinR;
  int pinG;
  int pinB;
  int pinCommon;

  void setupPWM(int pin);

public:
  RGBLed(int redPin, int greenPin, int bluePin);
  void setRed(int value);
  void setGreen(int value);
  void setBlue(int value);
  void setColor(int r, int g, int b);
  void clear();
};

#endif