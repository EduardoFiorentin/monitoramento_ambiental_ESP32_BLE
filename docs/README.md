# Monitoramento de temperatura, umidade e controle de atuadores com ESP 32 e BLE

---

## 1. Introdução
Esta documentação descreve as implementações do projeto. Inicialmente, é apresentada uma visão geral dos objetivos do projeto e implementações. Em seguida, são detalhadas as tecnologias, técnicas implementadas e funcionamento do firmware (ESP32) e da aplicação móvel (Flutter).

O projeto é estruturado da seguinte maneira: 
```
📦 raiz-do-repositorio
 ┣ 📂 apk/
 ┃ ┗ 📜 app-release.apk                   # Arquivo binário gerado para instalação no Android
 ┣ 📂 docs/                               # Documentação exigida pelo trabalho
 ┃ ┣ 📜 README.md                         # Documentação principal do projeto
 ┃ ┣ 📜 diagrama_classes.png              # Diagrama de classes do firmware
 ┃ ┣ 📜 fluxograma_firmware.png           # Fluxograma do firmware (setup, loop e callbacks)
 ┃ ┗ 📜 tabela_gatt.md                    # Tabela GATT detalhada com UUIDs e propriedades
 ┣ 📂 lib/                                # Código-fonte do aplicativo mobile (Flutter)
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

<!-- Exemplo de pinguins:
<div align="center">
  <img src="./images.jpeg" width="100%">
</div> -->


graph TD
    A[Início] --> B{Decisão}
    B -->|Sim| C[Processo 1]
    B -->|Não| D[Processo 2]
    C --> E[Fim]
    D --> E

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
## 3. Descrição do Firmware
A arquitetura do firmware foi pensada para modularidade, segurança e eficiência na transferência de dados sobre o protocolo Bluetooth Low Energy (BLE). Todo o sistema foi construído em C++ utilizando a biblioteca otimizada NimBLE-Arduino. Abaixo, o funcionamento do firmware é detalhado em uma progressão lógica.


### 3.1. Encapsulamento e Modularidade
Para garantir a manutenibilidade, evitar o acoplamento excessivo de responsabilidades e facilitar a leitura, diversas lógicas de controle de hardware e protocolo foram encapsuladas em classes específicas e posteriormente instanciadas no arquivo raiz (`sketch.ino`). As abstrações implementadas são:
- **Bluetooth** (`BleController`): Centraliza a configuração do servidor NimBLE, controle de serviços, características (GATT), gerenciamento de segurança e notificações do protocolo BLE..
- **Botões** (`PulldownButton`): Implementa a leitura de botões do tipo push-button sob lógica pull-down, incorporando internamente o tratamento de debounce (ruído de contato) através da verificação de tempo via `millis()`.
- **Switches** (`SwitchPullDown`): Semelhante aos botões, mas focado no monitoramento de chaves estáticas de dois estados, levantando sinalizadores (flags) de mudança de estado de forma confiável.
- led RGB (`RGBLed`): Abstrai a complexidade do controle PWM no ESP32 (utilizando a API `ledc`), permitindo o ajuste de cor direta através de parâmetros RGB de 0 a 255 via chamada `void setColor(int r, int g, int b);` . 
- **Leds** (`SimpleLed`): Simplifica a operação de pinos digitais de saída, abstraindo diretrizes como `pinMode` e `digitalWrite` em métodos literais como `setOn()` e `toggle()`. 
- **Temporização** (`Timer`): Classe dedicada à execução de lógicas não-bloqueantes. Recebe um intervalo em milissegundos e um ponteiro de função (callback), acionando-o automaticamente apenas quando o tempo estipulado é alcançado. Internamente, previne problemas de drift (desvio de tempo) e o overflow do registrador de milissegundos.  


Desta forma, o arquivo principal atua primariamente como uma máquina de estados e orquestrador. Ele instancia os controladores, delega os callbacks e processa o loop principal chamando os métodos de atualização (`.update()`), trabalhando sobre interfaces padronizadas que escondem a complexidade do hardware.


### 3.2. Bluetooth: Inicialização, Segurança e Advertising
A rotina de inicialização do BLE foi customizada para atender os requisitos de desempenho e segurança. O módulo atua como um Servidor BLE e, durante o anúncio (Advertising), sua frequência de transmissão é limitada a intervalos de 400ms (`BLE_ADVERTISING_INTERVAL`) com o objetivo de reduzir o consumo energético do ESP32 enquanto aguarda conexões.  

Para proteger o controle dos atuadores contra acessos não autorizados, a pilha de segurança do NimBLE foi configurada para forçar pareamento criptografado com proteção MITM (Man-In-The-Middle). A conexão exige a entrada de uma senha estática de 6 dígitos (Passkey) estipulada em código (`BLE_PASSWORD`).  

Após o pareamento, varios dos parâmetros da conexão são alterados (Connection Update Request) para exigir tempos de resposta mais curtos (mínimo de 50ms e máximo de 100ms - `BLE_MIN_CONNECT_INTERVAL` e `BLE_MAX_CONNECT_INTERVAL`), com latência escrava zerada (Slave Latency - `BLE_SLAVE_LATENCI`) para garantir fluidez aos comandos do aplicativo e timeout de supervisão (Supervision Timeout - `BLE_SUPERVISION_TIMEOUT`) de 2 segundos para detectar quedas abruptas de conexão.

Todas as configurações citadas podem ser encontradas e modificadas em `BleController.h`.



### Arquitetura do Perfil GATT (Serviços e Características)

A comunicação entre o microcontrolador ESP32 (Servidor) e o aplicativo mobile (Cliente) é estruturada sobre o protocolo BLE (Bluetooth Low Energy) utilizando o perfil genérico de atributos (GATT). 

Para otimizar o envio de dados e separar logicamente as responsabilidades do sistema, foram definidos três serviços principais contendo suas respectivas características. O sistema implementa estratégias de empacotamento em bytes e operações *bitwise* para reduzir o *overhead* de transmissão.

Abaixo, a especificação técnica completa adotada no firmware:

| Serviço (UUID) | Característica (UUID) | Propriedades | Descrição do Payload e Funcionamento |
| :--- | :--- | :--- | :--- |
| **Serviço Ambiental**<br>`0x181A`<br>*(Standard Env Sensing)* | **Dados Atuais**<br>`f52de2f0-5d97-42f3-933f-6b299132861d` | `Read`, `Notify` | Envia um pacote binário otimizado de 6 bytes (`EnvDataPayload`) contendo: <br>- *Bytes 0-1*: Temp. Celsius (`int16_t`)<br>- *Bytes 2-3*: Temp. Fahrenheit (`int16_t`)<br>- *Bytes 4-5*: Umidade (`uint16_t`)<br>O App divide os valores por 100 para restaurar as casas decimais. |
| | **Gráfico Histórico**<br>`614e74cf-1814-45fc-8602-3263376705e3` | `Read` | Interface de leitura para que o cliente realize o download (Read Request) de pacotes com dados históricos retidos na memória do ESP32. |
| **Controle de Atuadores**<br>`d6ca719a-7ae1-485a-bf63-ac03fdf84527`<br>*(Customizado 128-bits)* | **LEDs Simples**<br>`1384d4f8-05b5-4d0e-8d4b-ecfa8a2ee4eb` | `Read`, `Write`, `Notify` | Controle e leitura do estado dos LEDs. Utiliza operações *bitwise* em 1 byte:<br>- *Bit 0*: Estado LED Vermelho<br>- *Bit 1*: Estado LED Verde<br>- *Bit 2*: Comando Reset Mín/Máx<br>O `Notify` sincroniza o App se houver acionamento manual (físico). |
| | **LED RGB**<br>`2214794a-21a9-4cb3-bc1d-d10aa147fad8` | `Write sem Resposta` | Envia matriz de cores em 3 bytes: `[R, G, B]` (0-255). O uso de *Write Without Response* evita travamentos na fila do GATT ao arrastar o dedo rapidamente no *Color Picker* do App. |
| | **Configuração / Trava**<br>`fc949d8b-c71e-4ee7-84a0-5c1fd772a999` | `Read`, `Notify` | Permite ao ESP32 informar o App sobre estados estruturais em 1 byte:<br>- *Bit 0*: Unidade de medida (0=C, 1=F)<br>- *Bit 1*: Trava de Hardware (1 = Bloqueado localmente via Switch 1). |
| **Métricas de Conexão**<br>`e01c7a1d-8c40-428c-ba7b-a7f7980120b8`<br>*(Customizado 128-bits)* | **RSSI (-dBm)**<br>`fe4e82d1-ea3e-43af-a72d-9b7622a8113c` | `Read`, `Notify` | Envia ativamente a intensidade do sinal lida diretamente do hardware de rádio em pacotes de 1 byte com sinal (`int8_t`). |
| | **Contador de Pacotes**<br>`9ecd2413-1a5e-490a-993c-da9f6f1259f9` | `Read` | Retorna o somatório de interações BLE dos últimos 60 segundos exatos. O App implementa *polling* a cada 2s sobre este endereço para gerar o gráfico na tela. |




### 3.3. Estratégias de Empacotamento de Dados (Camada GATT)
Para evitar o desperdício de banda e o aumento de overhead na conversão de tipos via Bluetooth, o projeto descarta o envio de strings em texto plano, utilizando formatos binários eficientes.


#### 3.3.1. Estruturas Empacotadas (Dados Ambientais)
Os valores de temperatura e umidade contêm casas decimais, e o envio de múltiplos `floats` via Bluetooth é custoso computacionalmente. A solução encontrada foi a utilização da estrutura `EnvDataPayload`, marcada com a diretiva de compilação _`attribute__((packed))` para inibir um possível alinhamento automático de memória feito pelo compilador. Os valores de ponto flutuante são multiplicados por 100 e convertidos para inteiros de 16 bits (`int16_t` e `uint16_t`). Assim, envia-se um pacote simples de apenas 6 bytes contendo Temperatura (°C), Temperatura (°F) e Umidade, que é desempacotado posteriormente no aplicativo móvel.


#### 3.3.2. Máscaras de Bits / Bitwise (Atuadores e Configuração)
O controle das funcionalidades que podiam ser descritas em estados booleanos, como os dados de configuração da unidade de temperatura apresentada no aplicativo, o bloqueio de hardware dos controles e comandos de sincronização do estado dos leds físicos, foram comprimidos aplicando operações de manipulação de bits (bitwise) em pacotes de um único byte (`uint8_t`).  

No envio de configurações do hardware local para o aplicativo, realizado pelo comando `void sendConfigData(bool lockSimpleLeds, bool measure)`, as variáveis 'bloqueio de hardware' e 'unidade de medida do aplicativo' são codificadas da seguinte maneira: 
- Bloqueio de hardware (`lockSimpleLeds`): 
    - 0 - controles do aplicativo liberado (via chaves físicas bloqueado).
    - 1 - controle dos leds bloqueados no aplicativo (via chaves físicas liberado)
- Unidade de medida (`measure`): 
    - 0 - Exibir dados de temperatura em graus Fahrenheit.
    - 1 - Exibir dados de temperatura em graus Celcius.

Os dois bits representando a unidade de medida e o bloqueio são alocados, respectivamente, nas posições 0 e 1 do byte com a utilização de operadores OR (`|`) e shifts (`<<`), e então este enviado ao aplicativo móvel.

Já na recepção de comandos enviados pelo aplicativo para o hardware, o byte recebido, que possui codificação semelhante à anterior, é lido com operadores AND (`&`). Nesta codificação, estão presentes:
- bit 0 - estado do LED 1 (1 - ligar / 0 - desligar)
- bit 1 - estado do LED 2 (1 - ligar / 0 - desligar)
- bit 3 - comando para reiniciar os valores de mínimo e máximo de temperatura e humidade armazenados localmente (1 - resetar).

Ao ler o byte recebido, as funções de callback (detalhadas na próxima seção) definidas pelo usuário para efetivar as alterações são chamadas.


### 3.4. Gestão Assíncrona e Segurança (Callbacks)

Toda a lógica que liga a recepçãode mensagens via BLE e a efetivação física das ações no hardware (como por exemplo, acionar um LED após receber o comando vindo da aplicação móvel) ocorre através da inversão de controle por Callbacks. 


<!-- TODO MELHORARRRRR - complementar especificação -->
Este modelo de chamada se deu necessário devido ao isolamento das camadas de comunicação e controle de estado.

O controlador BLE instancia classes herdadas como NimBLEServerCallbacks e NimBLECharacteristicCallbacks


<!-- TODO Afofar um pouco esta transição entre parágrafos -->

Quando o celular escreve em uma característica de LED, a função `onWrite` no `BleController` processa os bytes brutos e aciona um ponteiro de função (`LedsCommandCallback`) previamente registrado pelo arquivo raiz. 

Essa abordagem mantém o controlador BLE isolado das regras de negócio. O script principal, ao captar este callback, submete a instrução à validação de segurança local: caso o Switch 1 físico indique "Controle Local" (`isLedsBlockedToApp == true`), o comando via aplicativo é silenciosamente ignorado e não atua sobre os LEDs.


<!-- TODO Complementar bastante essa explicação - afofar e dar mais detalhes -->
### 3.5. Telemetria e Indicadores Operacionais
Para atender ao requisito de monitoramento do link de dados, a camada do ESP32 processa indicadores de conexão de maneira ativa e passiva.

- Sinal de Conexão (RSSI): Uma chamada de baixo nível (`ble_gap_conn_rssi`) determina a intensidade de sinal em decibéis, e o notifica ativamente ao cliente a cada `BLE_RSSI_TRANSMISSION_INTERVAL` segundos através de um temporizador. 

- Contagem do número de notificações: O dispositivo contabiliza a emissão de cada notificação usando um vetor estático circular de 60 posições (`notifyBuckets`). A cada segundo, o índice do vetor - controlado por um temporizador externo ao controlador de BLE, que chama a cada 1 segundo o método `void updateNotificationWindow()` - avança, sendo zerado em seguida. O total de notificações lidas pelo aplicativo representa sempre a soma do vetor inteiro, compondo os dados reais dos últimos 60 segundos.  

### 3.6. Sincronismo e Gestão de Tempo (A Lógica não-bloqueante)

A principal vantagem da arquitetura implementada é a não utilização de funções bloqueantes que paralisam o microcontrolador, impedindo leituras de hardware ou manutenção de rádio. O loop contínuo (função `loop()`) processa leituras de botões e sensores e atualiza a máquina de estados em altíssima velocidade.  

A cadência de eventos lentos é governada por instâncias da classe `Timer`. O envio de dados ao celular (`envDataTransmitionTimer`), as atualizações de RSSI (`rssiTransmitionTimer`) e a rotação da janela de telemetria (`notificationWindowTimer`) são executados em instâncias paralelas não-bloqueantes. Até mesmo a restrição de tempo do sensor DHT22 (que requer intervalos de 4 segundos entre as coletas) é tratada verificando a diferença entre o timestamp de inicialização e o tempo corrido, evitando travamentos no laço principal do firmware.



--- 
## 4. Descrição da aplicação mobile

O cliente móvel foi desenvolvido utilizando o framework Flutter, garantindo uma interface fluida, reativa e compatível com as exigências de sistemas Android modernos (versão 10+). A comunicação com a camada de hardware é intermediada pela biblioteca `flutter_blue_plus`, que oferece controle de baixo nível sobre a pilha Bluetooth do sistema operacional.

A arquitetura do aplicativo divide as responsabilidades em seções lógicas independentes, otimizando o gerenciamento de estado e a alocação de memória do dispositivo móvel.

O código fonte principal do aplicativo pode ser encontrado em `apk/lib`.


### 4.1. Escaneamento, Permissões e Handshake de Segurança

A tela inicial (`ConnectionScreen`) atua como a porta de entrada segura do sistema. Antes de inicializar o rádio BLE, o aplicativo gerencia dinamicamente as permissões de sistema exigidas pelo Android (Bluetooth Scan, Connect e Location) através do pacote `permission_handler`, garantindo que não ocorram falhas de acesso.

Durante o escaneamento, o aplicativo aplica um filtro para exibir exclusivamente dispositivos cujo pacote de advertising contenha o nome esperado (`ESP32_NimBLE_Eduardo`). O fluxo de conexão implementa os requisitos de segurança mitigando ataques MITM: a chamada `device.createBond()` força a requisição do sistema operacional para que o usuário insira o Passkey. Caso o pareamento seja rejeitado ou a senha incorreta, a conexão é abortada de forma limpa, liberando a thread.

### 4.2. Gerenciamento do Ciclo de Vida (Dashboard)
Uma vez conectado, o usuário é redirecionado ao `DashboardScreen`, que orquestra a navegação entre os três painéis principais usando um `BottomNavigationBar`. Esta tela possui duas responsabilidades principais:

- **Resiliência e Auto-Reconexão**: Uma escuta (`StreamSubscription`) monitora continuamente o estado do rádio. Se o dispositivo sofrer uma desconexão não intencional (por perda de sinal ou reinicialização do ESP32), o aplicativo exibe um alerta vermelho em tela e entra em um laço de tentativas de reconexão automática em background, restaurando a sessão de forma transparente quando o sinal retorna.

- **Desconexão Segura (Graceful Shutdown)**: Para evitar conexões pendentes (dangling connections) e vazamento de memória (memory leaks), o widget `PopScope` foi utilizado para interceptar a ação do botão nativo de "voltar" do smartphone. Quando o usuário decide sair, o aplicativo cancela as escutas, dispara o comando de desconexão e destrói as instâncias antes de retornar à tela inicial.



### 4.3. Painel de Monitoramento: Desempacotamento e Plotagem
A seção de monitoramento (`MonitoringSection`) subscreve-se às características do Serviço GATT fornecido pelo. O aplicativo implementa a lógica inversa do firmware para otimização de banda: os 6 bytes recebidos do hardware são alocados em um `ByteData`, de onde se extraem os valores brutos como inteiros de 16 bits Little-Endian (`getInt16` e `getUint16`), que são então divididos por 100.0 para resgatar a precisão de ponto flutuante das temperaturas e umidade.

Os gráficos históricos dinâmicos são construídos usando a biblioteca `fl_chart`. O aplicativo mantém o controle da cardinalidade dos dados utilizando listas restritas a 60 pontos (`FlSpot`); quando um novo dado chega, o mais antigo é removido da fila rotativa, mantendo a janela de exibição sempre fluida e representando os minutos mais recentes da coleta.


### 4.4. Painel de Controle: Sincronismo e UX Condicional

A interface de atuação (`ControlSection`) não apenas envia comandos, mas reflete o estado real e as restrições impostas pelo hardware.

Para respeitar o bloqueio físico (acionado pelo Switch 1 da protoboard), o app subscreve à característica de configuração do dispositivo. Caso a flag de bloqueio (`isHardwareLocked`) seja acionada, o aplicativo reage visualmente envolvendo todos os controles em um IgnorePointer e reduzindo a opacidade (_Opacity_), impossibilitando interações de toque e alertando o usuário de que o dispositivo está em "Modo Local".

A manipulação dos atuadores segue padrões específicos:

- **LEDs Simples**: Comandos são enviados mascarando os booleanos dos botões virtuais em um único payload de 1 byte via operação matemática (ex: `payload |= 0x01` para o LED Vermelho).

- **LED RGB**: Um Color Picker converte a cor escolhida na interface visual para três parâmetros (R, G, B) e os envia ao microcontrolador sob a diretiva _WriteWithoutResponse_, garantindo que o envio contínuo gerado pelo arrastar do dedo na paleta de cores não cause engarrafamento na fila de requisições do Bluetooth.

### 4.5. Painel de Sinal: Auditoria de Conexão Ativa e Passiva
O terceiro painel (`ConnectionMetricsSection`) foi desenhado para expor informações sobre a estabilidade do link de comunicação. Para otimizar os recursos do dispositivo móvel e do hardware, foram adotadas duas estratégias de leitura concorrentes:

- **Leitura Passiva (RSSI)**: O sinal é recebido e processado via *Notify*. Como a força do sinal (dBm) trafega via int8 (com sinal), mas a linguagem Dart tipifica nativamente bytes sem sinal (0-255), aplica-se um tratamento condicional no buffer recebido (`bytes.first > 127 ? bytes.first - 256 : bytes.first`) para recompor o valor negativo correto da atenuação do sinal.

`Leitura Ativa (Polling de Notificações)`: Ao invés de o ESP32 sobrecarregar a rede notificando sempre que a janela rotativa de pacotes muda, o aplicativo instancia um `Timer.periodic` de 2 segundos. Este timer dispara comandos de leitura ativa (Read Request) para a característica do contador.

--- 
## 5. Instruções de Compilação e Instalação do Aplicativo
O aplicativo móvel foi projetado para operar em smartphones com o sistema operacional Android 10 ou superior (API nível 29+). Para reproduzir o ambiente de desenvolvimento, compilar o código-fonte a partir do zero ou gerar o pacote de instalação final (APK), siga os procedimentos descritos abaixo.


<!-- TODO Fazer diretório bin -->
Caso prefira, é possível também baixar e instalar a versão compilada que se encontra no diretório `/bin` 


### 5.1. Pré-requisitos do Ambiente
Antes de iniciar, certifique-se de que a sua máquina possui as seguintes ferramentas devidamente instaladas e configuradas nas variáveis de ambiente do sistema operacional:

- **Flutter SDK**: Versão estável instalada. Certifique-se de que o comando `flutter doctor` seja executado no terminal e não aponte nenhuma pendência crítica na plataforma Android.

- **Java Development Kit (JDK)**: Versão 17 instalada, necessária para a execução do ecossistema de compilação do Android (Gradle).

- **Android SDK**: Componentes de linha de comando, Android SDK Build-Tools e a plataforma correspondente à API do Android alvo instalados através do gerenciador do Android Studio.

- **Dispositivo Físico de Testes**: Um smartphone rodando Android 10 ou superior, com a função de "Opções do Desenvolvedor" e a "Depuração USB" ativadas nas configurações do sistema. É fortemente recomendado o uso de um aparelho físico, uma vez que emuladores Android padrão possuem restrições severas ou ausência de suporte completo para emulação de hardware de rádio Bluetooth Low Energy (BLE).

### 5.2. Preparação do Código e Dependências
Com o ambiente devidamente configurado, execute os comandos a seguir no terminal de sua máquina para preparar o projeto:

Primeiro, navegue até a pasta raiz do projeto mobile onde se encontra o arquivo de configuração de dependências `pubspec.yaml`.

Em seguida, execute o comando de limpeza de cache para garantir que nenhuma estrutura residual antiga interfira no processo atual:
```bash
flutter clean
```


Depois, execute o comando de instalação de pacotes para baixar e indexar todas as bibliotecas externas declaradas no projeto (incluindo o framework de comunicação Bluetooth, o renderizador de gráficos e o seletor de cores da interface):

```bash
flutter pub get
```


### 5.3. Configurações Específicas do Android
O aplicativo utiliza permissões explícitas de hardware para interagir com a antena Bluetooth e com os serviços de localização (requisito obrigatório do ecossistema Android para o escaneamento de pacotes BLE). Certifique-se de que o arquivo de manifesto do aplicativo (`android/app/src/main/AndroidManifest.xml`) contenha as diretivas de uso de recursos para varredura Bluetooth, conexão Bluetooth e localização de alta precisão (Fine Location).

Adicionalmente, verifique o arquivo de configuração do Gradle a nível de aplicativo ("`android/app/build.gradle`") para garantir que o parâmetro `minSdkVersion` esteja definido com o valor mínimo requerido pelas bibliotecas de comunicação periférica utilizadas.

### 5.4. Processo de Compilação
Para gerar o arquivo binário independente e otimizado para distribuição (conforme exigido nos entregáveis do projeto), você deve realizar a compilação em *Release Mode*. No terminal do seu computador, execute a seguinte instrução:

```bash
flutter build apk --release
```

Este comando aciona o compilador do Flutter e as ferramentas do Android SDK para realizar tarefas como a otimização de árvores de componentes, a minificação do código Dart e o empacotamento dos recursos em um arquivo binário único.

Ao final do processo de compilação com sucesso, o terminal exibirá o caminho exato do arquivo gerado, que por padrão será alocado na estrutura interna de pastas do projeto em: `build/app/outputs/flutter-apk/app-release.apk`.

### 5.5. Métodos de Instalação no Dispositivo
Você pode instalar o aplicativo no smartphone de duas maneiras distintas:

**Método 1**: Instalação Direta via APK (Produção)
Transfira o arquivo "`app-release.apk`" gerado na seção anterior diretamente para a memória interna do smartphone Android através de um cabo USB, e-mail ou serviço de nuvem. No gerenciador de arquivos do celular, toque sobre o arquivo APK. Caso o sistema operacional exiba um aviso de segurança, conceda a permissão temporária para "Instalar aplicativos de fontes desconhecidas". O aplicativo será instalado de forma permanente no menu do sistema.

**Método 2**: Execução em Modo de Depuração (Desenvolvimento)
Se você preferir rodar o aplicativo conectado ao computador para acompanhar os logs em tempo real através do terminal, conecte o smartphone ao computador via cabo USB com a depuração ativada. 

**OBS: Para este modo, é obrigatório a ativação das configurações "Opções do Desenvolvedor" e "Depuração USB".**

No terminal, execute o seguinte comando:
```sh
flutter run
```

O Flutter irá compilar uma versão de desenvolvimento, injetá-la temporariamente no dispositivo e estabelecer uma ponte de comunicação assíncrona para permitir o monitoramento das rotinas de conexão e desempacotamento de dados do ESP32.