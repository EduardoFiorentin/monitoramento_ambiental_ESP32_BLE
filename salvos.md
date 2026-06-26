O projeto é estruturado da seguinte maneira: 
```
📦 raiz-do-repositorio
 ┣ 📂 bin/
 ┃ ┗ 📜 app-release.apk                   # Arquivo binário gerado para instalação no Android
 ┣ 📂 docs/                               # Documentação exigida pelo trabalho
 ┃ ┗ 📜 README.md                         # Documentação principal do projeto
 ┣ 📂 /apk/lib/                                # Código-fonte do aplicativo mobile (Flutter)
 ┃ ┣ 📂 screens/
 ┃ ┃ ┣ 📜 connection_metrics_section.dart # Painel de métricas de conexão, RSSI e contador de pacotes
 ┃ ┃ ┣ 📜 connection_screen.dart          # Tela de escaneamento BLE e pareamento seguro
 ┃ ┃ ┣ 📜 control_section.dart            # Painel de atuação (UX reativa para Leds Simples e RGB)
 ┃ ┃ ┣ 📜 dashboard_screen.dart           # Orquestrador de navegação, reconexão e ciclo de vida
 ┃ ┃ ┗ 📜 monitoring_section.dart         # Painel de gráficos e plotagem do histórico DHT22
 ┃ ┗ 📜 main.dart                         # Ponto de entrada e configuração do tema do aplicativo
 ┣ 📂 sketch/                             # Código-fonte do firmware embarcado (ESP32 / C++)
 ┃ ┣ 📜 BleController.cpp                 # Implementação das regras GATT, callbacks e segurança
 ┃ ┣ 📜 BleController.h                   # Header do controlador Bluetooth (NimBLE)
 ┃ ┣ 📜 PulldownButton.cpp                # Implementação de debounce e leitura para push-buttons
 ┃ ┣ 📜 PulldownButton.h                  # Header da classe de botões físicos
 ┃ ┣ 📜 RGBLed.cpp                        # Implementação das operações via PWM (ledc)
 ┃ ┣ 📜 RGBLed.h                          # Header do controlador do LED RGB
 ┃ ┣ 📜 SimpleLed.cpp                     # Implementação de métodos de toggle e estados lógicos
 ┃ ┣ 📜 SimpleLed.h                       # Header da classe de abstração de LEDs básicos
 ┃ ┣ 📜 SwitchPullDown.cpp                # Implementação do tratamento contínuo de switches
 ┃ ┣ 📜 SwitchPullDown.h                  # Header da classe de leitura de chaves estáticas
 ┃ ┣ 📜 Timer.cpp                         # Implementação da rotina não-bloqueante para tarefas
 ┃ ┣ 📜 Timer.h                           # Header do controlador de tempo via millis()
 ┃ ┗ 📜 sketch.ino                        # Arquivo principal (Máquina de estados, LCD e Orquestrador)
 ┗ 📜 README.md                           # Documentação central do projeto
```



# final da 2.1 Arquitetura do Firmware

O diagrama abaixo apresenta a estrutura das classes utilizadas no firmware.

```mermaid
%%{init: {'theme': 'default', 'themeVariables': { 'fontSize': '14px', 'fontFamily': 'arial'}}}%%
classDiagram
    direction TB
    
    class BleController {
      -NimBLEServer* server
      -NimBLEService* envMonitoringService
      -NimBLEService* actuatorControllService
      -NimBLEService* connectIndicatorService
      -NimBLEServerCallbacks* customBLEServerCallback
      -NimBLECharacteristicCallbacks* customBLECharCallback
      -NimBLECharacteristic* dataCharacteristic
      -NimBLECharacteristic* dataHystCharacteristic
      -NimBLECharacteristic* ledsCharacteristic
      -NimBLECharacteristic* rgbLedCharacteristic
      -NimBLECharacteristic* deviceConfigCharacteristic
      -NimBLECharacteristic* rssiCharacteristic
      -NimBLECharacteristic* notifyCountCharacteristic
      -NimBLEAdvertising* pAdvertising
      -bool deviceConnected
      -uint16_t notifyBuckets[60]
      -uint8_t currentBucketIndex
      -unsigned long lastBucketShiftTime
      -unsigned long lastRssiNotifyTime
      -void registerNotification()

      +LedsCommandCallback onLedsCommand
      +RgbCommandCallback onRgbCommand
      +OnClientConnectCallback onClientConnectCallback
      +OnClientDisconnectCallback onClientDisconnectCallback
      
      +BleController()
      +void begin()
      +bool isAdvertising()
      +bool hasDeviceConnected()
      +void setTemperature(float temp, float humidity)
      +void sendAmbientData(float temperature, float humidity)
      +void sendConfigData(bool lockSimpleLeds, bool measure)
      +void sendLocalLedsState(bool led1, bool led2, bool resetMinMax)
      +void processIndicators()
      +void notifyRssi()
      +void updateNotificationWindow()
      +void setLedsCallback(LedsCommandCallback cb)
      +void setRgbCallback(RgbCommandCallback cb)
      +void setClientConnectCallback(OnClientConnectCallback cb)
      +void setClientDisconnectCallback(OnClientDisconnectCallback cb)
    }

    class SimpleLed {
      -int _pin
      -bool _state
      +SimpleLed(int pin)
      +void begin()
      +void setOn()
      +void setOff()
      +void toggle()
      +bool isOn() const
    }

    class RGBLed {
      -int pinR
      -int pinG
      -int pinB
      -int pinCommon
      -void setupPWM(int pin)
      +RGBLed(int redPin, int greenPin, int bluePin)
      +void begin()
      +void setRed(int value)
      +void setGreen(int value)
      +void setBlue(int value)
      +void setColor(int r, int g, int b)
      +void clear()
    }

    class PulldownButton {
      -int pin
      -int state
      -int lastState
      -bool pressedFlag
      -unsigned long lastClickTime
      -unsigned long debounceTime
      +PulldownButton(int pin)
      +void begin()
      +void update()
      +int getState()
      +bool wasPressed()
    }

    class SwitchPullDown {
      -int pin
      -int state
      -int lastState
      -bool changedFlag
      -unsigned long lastDebounceTime
      -unsigned long debounceTime
      +SwitchPullDown(int pin)
      +void begin()
      +void update()
      +bool isOn()
      +bool hasChanged()
    }

    class Timer {
      -uint32_t _interval
      -uint32_t _previousMillis
      -TimerCallback _callback
      -bool _isRunning
      +Timer(uint32_t intervalMillis, TimerCallback callback)
      +void start()
      +void stop()
      +void update()
      +void setInterval(uint32_t intervalMillis)
      +void setCallback(TimerCallback callback)
      +bool isRunning() const
    }

    sketch_ino *-- BleController : Instancia
    sketch_ino *-- SimpleLed : Instancia
    sketch_ino *-- RGBLed : Instancia
    sketch_ino *-- PulldownButton : Instancia
    sketch_ino *-- SwitchPullDown : Instancia
    sketch_ino *-- Timer : Instancia
    
    BleController ..> sketch_ino : Dispara Callbacks
```

Detalhes de implementação serão apresentados na seção [Descrição do Firmware](#3-descrição-do-firmware).




# final da 3.5. Gestão Assíncrona e Segurança (Callbacks)

O diagrama abaixo apresenta, como exemplo, o fluxo de execução dos comandos de controle dos leds simples, desde o recebimento dos comandos enviados pelo aplicativo até a reflexão das ordens nos atuadores em hardware. 

```mermaid
%%{init: {'theme': 'default', 'themeVariables': { 'fontSize': '15px'}}}%%
flowchart TD
    A([App Envia<br>Comando GATT]) --> B(NimBLE Rx:<br>Pacote Recebido)
    
    subgraph Camada BleController
        B --> C[onWrite da<br>Característica]
        C --> D{UUID é de<br>LED Simples?}
        D -- Sim --> E[Decodifica Bytes via<br>Operador Lógico &]
        E --> F[Chama Ponteiro de Função<br>LedsCommandCallback]
    end

    subgraph Camada sketch.ino
        F --> G((Início da Execução<br>do Callback))
        G --> H{isLedsBlockedToApp<br>== true?}
        
        H -- Sim<br>(Trava Ativa) --> I[Log Serial:<br>Comando Ignorado]
        I --> J([Fim da Rotina -<br>Hardware Intacto])
        
        H -- Não<br>(Liberado) --> K[Atualiza instâncias locais<br>de SimpleLed]
        K --> L[Comando digitalWrite<br>é acionado fisicamente]
        L --> M([Fim da Rotina -<br>LEDs Atualizados])
    end
    
    style H fill:#ffcccb,stroke:#ff0000,stroke-width:2px;
    style L fill:#d4edda,stroke:#28a745,stroke-width:2px;
```