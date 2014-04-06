$NOLIST

;MAKE SURE TO ADD A 30-BYTE BUFFER IN DSEG. "buffer: ds 30" IN DSEG

FREQ   EQU 33333333
BAUD   EQU 115200
T2LOAD EQU 65536-(FREQ/(32*BAUD))

CSEG

; Configure the serial port and baud rate using timer 2
InitSerialPort:
	clr TR2 ; Disable timer 2
	mov T2CON, #30H ; RCLK=1, TCLK=1 
	mov RCAP2H, #high(T2LOAD)  
	mov RCAP2L, #low(T2LOAD)
	setb TR2 ; Enable timer 2
	mov SCON, #52H
	ret

; Send a character through the serial port
putchar:
    JNB TI, putchar
    CLR TI
    MOV SBUF, a
    RET

; Send a constant-zero-terminated string through the serial port
SendString:
    CLR A
    MOVC A, @A+DPTR
    JZ SSDone
    LCALL putchar
    INC DPTR
    SJMP SendString
SSDone:
    ret
 

SendTemp:
	mov dptr, #asciiLUT
	; send Digit 2
	mov A, bcd+1
    anl a, #0fh
    movc A,@A+dptr
    lcall putchar
	; send Digit 1
    mov A, bcd+0
    swap a
    anl a, #0fh
    movc A,@A+dptr
    lcall putchar
	; send Digit 0
    mov A, bcd+0
    anl a, #0fh
    movc A,@A+dptr
    lcall putchar
    mov a, state_code
    add a, #30H
    lcall putchar
    mov a, #10
    movc A,@A+dptr
    lcall putchar
    mov a, #11
    movc A,@A+dptr
    lcall putchar
    ret
    
getchar:
    jnb RI, getchar
    clr RI
    mov a, SBUF
    ret

GetString:
    mov R0, #buffer
GSLoop:
    lcall getchar
    push acc
    clr c
    subb a, #10H
    pop acc
    jc GSDone
    MOV @R0, A
    inc R0
    cjne R0, #(buffer+15), GSLoop ; Prevent buffer overrun
GSDone:
    clr a
    mov @R0, a
    ret

parseString: ;least significat in 0
	mov temp_soak_temp+0, buffer+3
	mov temp_soak_temp+1, buffer+2
	mov temp_soak_temp+2, buffer+1
	
	mov temp_soak_time+0, buffer+7
	mov temp_soak_time+1, buffer+6
	mov temp_soak_time+2, buffer+5
	
	mov temp_reflow_temp+0, buffer+11
	mov temp_reflow_temp+1, buffer+10
	mov temp_reflow_temp+2, buffer+9
	
	mov temp_reflow_time+0, buffer+15
	mov temp_reflow_time+1, buffer+14
	mov temp_reflow_time+2, buffer+13
	
	ret

display_serial:
	lcall clearScreen
	lcall GetString
	LCD_put_mac(buffer+1)
	LCD_put_mac(buffer+2)
	LCD_put_mac(buffer+3)
	LCD_put_mac(buffer+4)
	LCD_put_mac(buffer+5)
	LCD_put_mac(buffer+6)
	LCD_put_mac(buffer+7)
	LCD_put_mac(buffer+8)
	LCD_put_mac(buffer+9)
	LCD_put_mac(buffer+10)
	LCD_put_mac(buffer+11)
	LCD_put_mac(buffer+12)
	LCD_put_mac(buffer+13)
	LCD_put_mac(buffer+14)
	LCD_put_mac(buffer+15)
	ret
	
$LIST