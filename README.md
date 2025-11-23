ppt 링크(./project2.pptx)

1. **프로젝트 목적**
    
    FPGA보드의 Seven Segment에 Stopwatch와 Watch의 값, 그리고 Sensor의 값(온습도, 거리)을 스위치에 따라 출력시키고자 함.
    
    또한 ComPortMaster를 통해 PC로 FPGA에 ‘단어’(문자열)를 보내서 보드를 제어하고, 역으로 Seven Segment 값을 PC에 출력하고자 함.
    
2. **기술 요약**
    - 언어: Verilog (Xlinx Vivado)
    - FPGA 보드: basys-3
    - 주요 기술
        - UART FIFO
            
            UART(Universal Asynchronous Recevier/Transmitter)
            
            통신 프로토콜, 8bit의 정보를(start, stop bit까지 포함하면 10bit) 전송함.
            
            9600bps의 baud tick을 사용하였으므로, 1byte 정보를 보내는데 1.04166ms이 걸림.
            
            - TX: Transmitter, 8bit를 1bit의 tx신호로 전송함
            
            - RX: Receiver, 받은 1bit의 rx신호를 8bit 정보로 해석함
            
            - 둘 다 “FSM의 형태”로 baud tick모듈로부터 신호를 받아 각각 전송할 신호를 만들고, 전송 받은 신호를 해석함.
            
            FIFO(First In First Out): UART TX/RX를 사용할 때, 긴 단어를 전송하고 받기 위한 buffer 역할.
            
            - RAM과 FIFO Control Unit로 구성되어 있음.
            
            - FIFO Control Unit은 FSM형태로 구성
            
            push, pop 입력신호에 따라
            
            r_addr(read address), w_addr(write address)를 조절하고
            
            상황에 따라 full, empty 신호를 출력함.
            
        - DHT11 Sensor(온습도 센서)
            - datasheet:
                
                [DHT11-Technical-Data-Sheet-Translated-Version-1143054.pdf](attachment:985c35fb-2bc8-4b5b-b15d-b1dc32f86fb2:DHT11-Technical-Data-Sheet-Translated-Version-1143054.pdf)
                
            - 특징: Dual Port로 통신
        - SR04 Sensor(초음파 거리 센서)
            - datasheet:
                
                [HCSR04.pdf](attachment:7a00283f-0e4b-4e19-bc81-0ac671c35f39:HCSR04.pdf)
                
            - 특징: Single Port로 통신
        
3. **주요 내용**
    1. 모듈 설계, 구현
        1. Stopwatch / Watch
            
            둘 모두 버튼 입력에 따라 동작하기 위해 FSM으로 구현돼 있음.
            
            스위치0을 통해 FND에 Stopwatch/Watch 둘 중 하나를 선택해서 출력함.
            
            스위치1을 통해 FND에 표시되는 데이터가 ‘시간_분’모드, ‘초_밀리초’모드로 변경 가능
            
            Stopwatch: run/stop 버튼을 눌러 동작시키거나 중지시킬 수 있음. clear 버튼을 누르면 시간을 0으로 초기화. 
            
            Watch: 항상 run 상태. clear 버튼으로 시간을 00:00:00:00 으로 변경할 수 있고, adjust_mode 버튼으로 시간, 분, 초 중 하나를 선택 후, adjust_up/down 버튼으로 해당위치를 증가/감소 시킬 수 있음.
            
        2. SR04 초음파 거리 센서
            
            ![image.png](attachment:0eb936e9-77bc-4c20-ae3f-2515c65d0910:image.png)
            
            SR04 CTRL 모듈에서 SR04로 data sheet의 통신 protocol에 맞게 trig신호를 보내주고(FSM 형태) echo를 받아서 거리를 계산하는 역할을 수행함. echo가 58us동안 온다면 그 거리는 1cm임.
            
            FND CTRL에서 8 bit 거리 신호를 처리하여 seven segment에 표시함.
            
        3. DHT11 온습도 센서
            
            ![image.png](attachment:2ce685fe-1650-45f6-be3f-4cf674f6aefd:image.png)
            
            DHT11 Control Unit(코드에서의 dht_fsm 모듈, FSM 형태)에서 센서에게 dht_io 포트를 통해 일정시간동안 start 신호를 주게 되면, 센서로부터 DHT11 Control Unit에게 같은 포트로 40bit의 데이터를 전송받음. 그 중 온도 데이터 8bit와 습도 데이터 8bit를 FND Controller에서 추출하고, seven segment에 표시함.
            
        4. UART_FIFO, ASCII SENDER
            
            ![image.png](attachment:45bccb0d-34ea-41cc-8490-123e29759e5f:image.png)
            
            ![image.png](attachment:754b2960-4940-4bb7-994d-0869361440be:image.png)
            
            UART(RX, TX모듈) - tx_data 8bit를 tx 1bit 포트로 pc에게 전송하고, rx 1bit 포트로 들어온 신호를 rx_data 8bit로 해독하여 FPGA에게 주는 역할. 예를 들어 rx로부터 받은 문자가 ‘T’이면 mode에 맞게(0: stopwatch 정보, 1: watch 정보, 2: sr04 정보, 3: dht11 정보) Ascii_sender에게 start 신호를 주고, 문자열을 PC에게 전송함.
            
            FIFO는 register file과 fifo control unit으로 구성되어 있으며, push 신호가 들어오면 데이터를 저장하고 pop신호가 들어오면 저장돼있던 데이터를(먼저 들어온 데이터부터) 출력하는 동작을 함. 차후에 PC로부터 문자’열’이 들어오면 그 문자열을 온전히 전송 받기 위해 설치하였음.
            
    2. 최종 TOP module
        
        ![image.png](attachment:fae42f13-9980-4d69-b2d2-f99493079b7c:image.png)
        
        위의 4가지 모듈을 모두 조합하여 최종적으로 위와 같은 Top module을 구성하였음.
        
        SR04, DHT11, stopwatch, watch 등의 data를 FPGA에서 내부적으로 처리하고 버튼과 스위치 입력에 따라 fnd에 출력되는 값이 달라짐. 또한 PC로부터 데이터를 받아 Stopwatch/Watch를 멈추는 등 제어를 할 수 있고, PC에 FPGA안의 모듈들의 정보 값들을 출력할 수 있음.
        

4. **Trouble Shooting, 개선 사항**
    1. Switch와 Uart통신의 제어 문제
        
        Stopwatch/Watch 모드를 변경할 때를 비롯해서 스위치를 사용함.
        
        Uart는 (button처럼) 하나의 tick 신호로 제어하도록 설계했음(통일성을 위해).
        
        ⇒ FPGA보드 우선 모드와 Uart우선 모드를 결정하는 switch를 하나 달아서 해결
        
        (Uart 명령어 별로 level을 변경할건지, tick을 보낼건지(switch처럼 동작할건지, button처럼 동작할건지)를 적절히 고려해서 해결할 수도 있었을 것 같다.)
        
    2. FPGA에서 PC로 단어(문자열)을 보낼 때 작동하는 “Ascii_sender 모듈” 설계 고찰
        
        모듈 내에 ‘단어를 전송할 양식’과 seven segment에 ‘표시될 값’을 저장해 두었다가 신호를 받으면 전송하는 방식으로 설계. 그래서 ascii_sender_stopwatch, _watch, _dht, _sr01 등 각각의 모듈을 만들었음.
        
        ⇒ 범용성을 위해 하나의 모듈로 만들고, 인스턴스할 때 ‘양식’과 ‘표시값’을 ascii 전송값으로 각각 (mux를 통해) 매칭해주었으면 더 좋았을 것.
        
        ![image.png](attachment:3411388e-cafa-41c7-9480-7a00874ed8b1:image.png)
        
    3. Sensor파트 - 나누기 연산에 의한 Negative Slack Error 문제
        
        초음파 거리 센서에서 걸린 시간(us)을 거리(cm)로 변환할 때, /58 을 해줘야함
        
        이 때, next_state를 기술하는 코드 안에서 연산을 수행할 경우 연산이 오래 걸려 F/F의 한 주기안에 끝나지 않음. Negative Slack Error가 발생함.
        
        ⇒ next_state 서술문 안에는 ‘시간 값’만 결정해주고, ‘거리 값’은 next_state밖에 assign문으로 할당하여 출력해서 해결.
        
        ⇒ 나눗셈 연산을 ‘곱셈과 shift 연산’으로 바꿔서 근삿값으로 연산하는 방법으로도 해결 가능했음.
        
        ex) 거리 = (us / 58)  ⇒  거리 = (us * 71) >> 12
