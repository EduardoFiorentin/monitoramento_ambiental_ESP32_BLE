#ifndef TIMER_H
#define TIMER_H

#include <Arduino.h>

// tipo para o ponteiro de função do callback
typedef void (*TimerCallback)();

class Timer {
private:
  uint32_t _interval;
  uint32_t _previousMillis;
  TimerCallback _callback;
  bool _isRunning;
public:
  /**
    * @brief Construtor da classe Timer
    * @param intervalMillis O intervalo em milissegundos
    * @param callback O ponteiro para a função que será executada
    */
  Timer(uint32_t intervalMillis, TimerCallback callback);

  // Métodos de controle
  void start();
  void stop();
  void update();


  void setInterval(uint32_t intervalMillis);
  void setCallback(TimerCallback callback);
  bool isRunning() const;
};

#endif // TIMER_H