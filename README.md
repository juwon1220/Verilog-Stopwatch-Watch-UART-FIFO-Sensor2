# Stopwatch-Watch-UART-FIFO-Sensor2
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
            
        - DHT Sensor(온습도 센서)
            
            datasheet: 
            
            특징: Dual Port로 통신
            
        - SR01 Sensor(초음파 거리 센서)
            
            datasheet: 
            
            특징: Single Port로 통신
            
        
3. **주요 내용(어떤 걸 했는지)** 
    1. 구조
        1. 코드 링크
        2. Top module 블럭 다이어그램, 동작 설명
            
            
        3. Module별 블럭 다이어그램, 동작 설명
        
    2. 시뮬레이션
    3. 검증

4. **Trouble Shooting, 개선 사항**
    1. Switch와 Uart통신의 제어 문제
        
        Stopwatch/Watch 모드를 변경할 때를 비롯해서 스위치를 사용함.
        
        Uart는 (button처럼) 하나의 tick 신호로 제어하도록 설계했음(통일성을 위해).
        
        ⇒ FPGA보드 우선 모드와 Uart우선 모드를 결정하는 switch를 하나 달아서 해결
        
        (Uart 명령어 별로 level을 변경할건지, tick을 보낼건지(switch처럼 동작할건지, button처럼 동작할건지)를 적절히 고려해서 해결할 수도 있었을 것 같다.)
        
    2. FPGA에서 PC로 단어(문자열)을 보낼 때 작동하는 “Ascii_sender 모듈” 설계 고찰
        
        모듈 내에 ‘단어를 전송할 양식’과 seven segment에 ‘표시될 값’을 저장해 두었다가 신호를 받으면 전송하는 방식으로 설계. 그래서 ascii_sender_stopwatch, _watch, _dht, _sr01 등 각각의 모듈을 만들었음.
        
        ⇒ 범용성을 위해 하나의 모듈로 만들고, 인스턴스할 때 ‘양식’과 ‘표시값’을 ascii 전송값으로 각각 (mux를 통해) 매칭해주었으면 더 좋았을 것.
        
    3. Sensor파트 - 나누기 연산에 의한 Negative Slack Error 문제
        
        초음파 거리 센서에서 걸린 시간(us)을 거리(cm)로 변환할 때, /58 을 해줘야함
        
        이 때, next_state를 기술하는 코드 안에서 연산을 수행할 경우 연산이 오래 걸려 F/F의 한 주기안에 끝나지 않음. Negative Slack Error가 발생함.
        
        ⇒ next_state 서술문 안에는 ‘시간 값’만 결정해주고, ‘거리 값’은 next_state밖에 assign문으로 할당하여 출력해서 해결.
