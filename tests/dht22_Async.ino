// Codigo para teste de leitura não bloqueante do DHT22
// Fica piscando um led a cada 1 segundo emnquanto imprime atualizações de leitura no console

#include <Arduino.h>
#include "DHT_Async.h"

// Configuração do Sensor DHT
#define DHT_SENSOR_TYPE DHT_TYPE_22
static const int DHT_SENSOR_PIN = 14;
DHT_Async dht_sensor(DHT_SENSOR_PIN, DHT_SENSOR_TYPE);

// Configuração do LED
static const int LED_PIN = 2;
unsigned long led_timestamp = 0;
bool led_state = false;

/*
 * Inicializa a porta serial e os pinos.
 */
void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
}

/*
 * Verifica o ambiente. Retorna true se a medição estiver pronta.
 */
static bool measure_environment(float *temperature, float *humidity) {
    static unsigned long measurement_timestamp = millis();

    /* Mede uma vez a cada quatro segundos. */
    if (millis() - measurement_timestamp > 4000ul) {
        if (dht_sensor.measure(temperature, humidity)) {
            measurement_timestamp = millis();
            return (true);
        }
    }

    return (false);
}

/*
 * Loop principal do programa.
 */
void loop() {
    float temperature;
    float humidity;

    // --- TAREFA 1: Ler o DHT (Não-bloqueante) ---
    if (measure_environment(&temperature, &humidity)) {
        Serial.print("T = ");
        Serial.print(temperature, 1);
        Serial.print(" deg. C, H = ");
        Serial.print(humidity, 1);
        Serial.println("%");
    }

    // --- TAREFA 2: Piscar o LED (Não-bloqueante) ---
    // Verifica se já passou 1 segundo (1000 milissegundos) desde a última mudança
    if (millis() - led_timestamp >= 1000ul) {
        led_timestamp = millis();       // Atualiza a referência de tempo
        led_state = !led_state;         // Inverte o estado atual do LED
        digitalWrite(LED_PIN, led_state); // Aplica o novo estado
    }
}