# Monitoramento de temperatura, umidade e controle de atuadores com ESP 32 e BLE

---

## 1. Introdução
Esta documentação descreve de forma macro e detalhada o funcionamento das implementações do projeto. São apresentados 

---
## 2. Visão geral do projeto

Este projeto apresenta o desenvolvimento de um sistema bidirecional de telemetria e controle baseado na tecnologia Bluetooth Low Energy (BLE). A solução integra um dispositivo embarcado (ESP32 atuando como Servidor GATT) e um aplicativo móvel (desenvolvido em Flutter, atuando como Cliente Central) para criar uma interface completa de hardware e software. 

O sistema permite o monitoramento de grandezas ambientais (temperatura e umidade), o acionamento de atuadores (LEDs simples e RGB) com suporte a bloqueio físico de segurança, e o acompanhamento de indicadores de qualidade da conexão em tempo real. O foco principal é a eficiência na transmissão de dados, utilizando o protocolo BLE para garantir baixo consumo de energia e alta responsividade.

### 2.1. Arquitetura do Firmware

O firmware foi desenvolvido em C++ sob o paradigma de Orientação a Objetos, utilizando a biblioteca `NimBLE-Arduino`. A arquitetura de software segue o Princípio da Responsabilidade Única (SRP), operando de forma totalmente não-bloqueante por meio da delegação de temporizadores para o laço de execução principal. 

O dispositivo opera tanto de forma autónoma (Modo Local) como subordinada (Modo Remoto), e inclui as seguintes funcionalidades:

- **Monitoramento**: Leitura contínua de temperatura e umidade através do sensor DHT22.
- **Atuadores**: Controle de acionamento de dois LEDs simples e de um LED RGB (PWM).
- **Interface Física**: Display LCD I2C (16x2) gerido por uma máquina de estados finitos (FSM) para navegação de dados, além de botões e switches físicos (pull-down) para comandos locais.
- **Trava de Hardware (Security Lock)**: Uma trava a nível do hardware que permite a um operador físico bloquear qualquer comando vindo da aplicação móvel.



### 2.2. Arquitetura de Software (Aplicação Móvel)

A aplicação móvel foi desenvolvida sobre o framework Flutter (Dart), projetada para atuar como o painel de controle e monitoramento do sistema. A arquitetura da interface de usuário está dividida em três seções principais:

- **Monitoramento Ambiental**: Apresentação dos dados de temperatura e umidade e renderização de gráficos históricos contínuos e dinâmicos.
- **Painel de Controle**: Interface para acionamento remoto dos LEDs simples e um seletor de cores HSV para o LED RGB. Este painel é reativo, bloqueando-se automaticamente caso a Trava de Hardware do ESP32 seja ativada fisicamente.
- **Métricas de Conexão**: Tela de monitoramento do sinal de rádio (gráfico de RSSI em dBm) e contagem da quantidade de notificações recebidas no último minuto.


A comunicação entre as aplicações é estabelecida exclusivamente via Bluetooth Low Energy, utilizando uma arquitetura GATT customizada, otimizada através de operações bitwise e estruturas de dados compactadas, garantindo um tráfego de rede mínimo e respostas em tempo curto.


Nas seções seguintes, são descritas as implementações do firmware e do aplicativo de forma detalhada, apresentando diagramas e fluxogramas.


---
## 3 Descrição do Firmware
A arquitetura do firmware foi pensada para modularidade, segurança e eficiência na transferência de dados sobre o protocolo Bluetooth Low Energy (BLE). Todo o sistema foi construído em C++ utilizando a biblioteca otimizada `NimBLE-Arduino`.

Abaixo, o funcionamento do firmware é detalhado em uma progressão lógica.


### 3.1. Encapsulamento
Em uma tentativa de evitar o famoso "codigo espaguete", diversas lógicas de controle globais foram encapsuladas em classes genéricas, e então instanciadas no arquivo raiz (`sketch.ino`). As funcionalidades encapsuladas (e classes que as implementam) são: 
- **Bluetooth** (`BleController`): Implementação da comunicação via BLE com dispositivos externos.
- **Botões** (`PulldownButton`): Implementação da detecção de clique sobre botão do tipo pushbutton, utilizando a lógica pulldown, além de tratamento para bounce.
- **Switches** (`SwitchPullDown`): Implementação da detecção de acionamento de botões do tipo switch com lógica pulldown, além de tratamento para bounce.
- led RGB (`RGBLed`): Implementação de controle automático de leds RGB, abstraíndo controles de `pinmode` e acionamento PWM. 
- **Leds** (`SimpleLed`): Implementação de controle automático de leds comuns, abstraíndo controles de `pinmode` e `digitalWrite`. 
- **Temporização** (`Timer`): Implementação de uma classe genérica de temporização que recebe um valor em milissegundos e uma função callback, e a partir do acionamento, executa a função de callback a cada passagem do tempo. Implementa também tratamento para drifts de tempo e estouro do registrador millis.


Desta forma, o arquivo principal fica dedicado ao instanciamento dos controladores, controle de estados da aplicação, delegação de callbacks e invocação de métodos de atualização, trabalhando exclusivamente sobre interfaces padronizadas que escondem complexidades como configurações de bluetooth, PWM, verificações de temporização ou debounce de botões. 



### 3.2. Bluetooth: Inicialização, Segurança e Advertising
A rotina de setup do Bluetooth configura o hardware antes de abrir as portas para conexões externas.


### 3.3. Estratégias de Empacotamento de Dados (Camada GATT)

#### 3.3.1. Estruturas Empacotadas (Dados Ambientais)
#### 3.3.2. Máscaras de Bits / Bitwise (Atuadores e Configuração)

### 3.4. Gestão Assíncrona e Segurança (Callbacks)

### 3.5. Telemetria e Indicadores Operacionais

### 3.6. Sincronismo e Gestão de Tempo (A Lógica não-bloqueante)