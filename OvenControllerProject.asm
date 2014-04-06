; EECE 281 Project 1
; Authors: Shivan, Albert, Samson, Wyatt, Bob, Connor

$MODDE2
org 0000H
	ljmp MyProgram
org 000BH
	ljmp ISR_timer0
org 001BH
	ljmp ISR_timer1

MISO   		EQU  	P1.7 ;input
MOSI   		EQU  	P1.5 ;output
SCLK   		EQU		P2.1 ;output
CE_ADC 		EQU	  	P1.3 ;output
SSR_CON 	EQU 	P0.5 ;output
LED_CON 	EQU 	P0.1 ;output
BUZZER_OUT 	EQU 	P3.1 ;output
STATE_CHECK_INPUTS	EQU	0
STATE_RAMP_TO_SOAK	EQU 1
STATE_SOAK			EQU 2
STATE_RAMP_TO_REFLOW	EQU 3
STATE_REFLOW		EQU 4
STATE_COOLDOWN		EQU 5

FREQ_0			EQU 100
FREQ_1			EQU 2000
TIMER0_RELOAD	EQU 65536-(FREQ/(12*FREQ_0))	;TIMER 0 is used to keep track of time
TIMER1_RELOAD	EQU 65536-(FREQ/(12*2*FREQ_1))	;TIMER 1 is used to create the buzz 

DSEG at 30H
x:				ds 2
y:				ds 2
bcd:			ds 3 ;temperature only needs 2 bytes to be displayed
time:			ds 3 ;time elapsed in seconds from when the user starts the soldering process in BCD
time_hex:		ds 2
time_entered:   ds 2 ;time at which we entered the last time-dependent state
time_elapsed: 	ds 2 ;time elapsed in the last time-dependent state
hundred_counter:	ds 1
val:			ds 3 ; used to hold the value of user input and assign accordingly
pwm_counter:	ds 1 ; counter for pwm'ing the Oven
temperature:	ds 2 ; temperature will be between 0 - 255, so only need 1 byte
;State codes: 	0 -> check_inputs		| The state codes are for the timer0 ISR to be able to figure
;				1 -> ramp_to_soak		| out what to do
;				2 -> soak
;				3 -> ramp_to_reflow
;				4 -> reflow
;				5 -> cooldown
;				6 -> short_beep
;				7 -> long_beep
state_code:		ds 1 
cold_junction:	ds 1 ;temperature from the LM335
hot_junction:	ds 1 ;temperature from the thermocouple

buffer:				ds 16	;serial input buffer
temp_soak_temp: 	ds 3	;constantly updated temps/times received from serial
temp_soak_time:		ds 3
temp_reflow_temp:	ds 3
temp_reflow_time: 	ds 3
soak_temp:			ds 3 	;permanent temps/times 
soak_temp_hex:		ds 2
soak_time:			ds 3
soak_time_hex:		ds 2
reflow_temp:		ds 3
reflow_temp_hex:	ds 2
reflow_time:		ds 3
reflow_time_hex:	ds 2

BSEG
mf:				dbit 1 ;math flag for math functions
t0f:			dbit 1 ;timer0 flag (for counter)
pwm:			dbit 1 ;if pwm is on and the state is "soak", the oven is on, otherwise off
oven_off_flag:	dbit 1

CSEG
$include(math16.asm)
$include(LCD_Display.asm)
$include(SPI.asm)
$include(serial_communication.asm)

myLUT:	; Look-up table for 7-seg displays
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9

asciiLUT:
	DB '0', '1', '2', '3', '4'
	DB '5', '6', '7', '8', '9'
	DB '\r', '\n'

;For converting a digital value from the thermocouple to a celsius temperature
thermocouple_look_up_table:
	DB 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8, 9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 17, 17, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24, 25, 25, 25, 25, 26, 26, 26, 26, 27, 27, 27, 27, 28, 28, 28, 28, 29, 29, 29, 29, 30, 30, 30, 30, 31, 31, 31, 31, 32, 32, 32, 32, 32, 33, 33, 33, 33, 34, 34, 34, 34, 35, 35, 35, 35, 36, 36, 36, 36, 37, 37, 37, 37, 38, 38, 38, 38, 39, 39, 39, 39, 40, 40, 40, 40, 41, 41, 41, 41, 42, 42, 42, 42, 43, 43, 43, 43, 44, 44, 44, 44, 45, 45, 45, 45, 46, 46, 46, 46, 47, 47, 47, 47, 48, 48, 48, 48, 48, 49, 49, 49, 49, 50, 50, 50, 50, 51, 51, 51, 51, 52, 52, 52, 52, 53, 53, 53, 53, 54, 54, 54, 54, 55, 55, 55, 55, 56, 56, 56, 56, 57, 57, 57, 57, 58, 58, 58, 58, 59, 59, 59, 59, 60, 60, 60, 60, 61, 61, 61, 61, 62, 62, 62, 62, 63, 63, 63, 63, 64, 64, 64, 64, 65, 65, 65, 65, 65, 66, 66, 66, 66, 67, 67, 67, 67, 68, 68, 68, 68, 69, 69, 69, 69, 70, 70, 70, 70, 71, 71, 71, 71, 72, 72, 72, 72, 73, 73, 73, 73, 74, 74, 74, 74, 75, 75, 75, 75, 76, 76, 76, 76, 77, 77, 77, 77, 78, 78, 78, 78, 79, 79, 79, 79, 80, 80, 80, 80, 81, 81, 81, 81, 81, 82, 82, 82, 82, 83, 83, 83, 83, 84, 84, 84, 84, 85, 85, 85, 85, 86, 86, 86, 86, 87, 87, 87, 87, 88, 88, 88, 88, 89, 89, 89, 89, 90, 90, 90, 90, 91, 91, 91, 91, 92, 92, 92, 92, 93, 93, 93, 93, 94, 94, 94, 94, 95, 95, 95, 95, 96, 96, 96, 96, 97, 97, 97, 97, 97, 98, 98, 98, 98, 99, 99, 99, 99, 100, 100, 100, 100, 101, 101, 101, 101, 102, 102, 102, 102, 103, 103, 103, 103, 104, 104, 104, 104, 105, 105, 105, 105, 106, 106, 106, 106, 107, 107, 107, 107, 108, 108, 108, 108, 109, 109, 109, 109, 110, 110, 110, 110, 111, 111, 111, 111, 112, 112, 112, 112, 113, 113, 113, 113, 113, 114, 114, 114, 114, 115, 115, 115, 115, 116, 116, 116, 116, 117, 117, 117, 117, 118, 118, 118, 118, 119, 119, 119, 119, 120, 120, 120, 120, 121, 121, 121, 121, 122, 122, 122, 122, 123, 123, 123, 123, 124, 124, 124, 124, 125, 125, 125, 125, 126, 126, 126, 126, 127, 127, 127, 127, 128, 128, 128, 128, 129, 129, 129, 129, 130, 130, 130, 130, 130, 131, 131, 131, 131, 132, 132, 132, 132, 133, 133, 133, 133, 134, 134, 134, 134, 135, 135, 135, 135, 136, 136, 136, 136, 137, 137, 137, 137, 138, 138, 138, 138, 139, 139, 139, 139, 140, 140, 140, 140, 141, 141, 141, 141, 142, 142, 142, 142, 143, 143, 143, 143, 144, 144, 144, 144, 145, 145, 145, 145, 146, 146, 146, 146, 146, 147, 147, 147, 147, 148, 148, 148, 148, 149, 149, 149, 149, 150, 150, 150, 150, 151, 151, 151, 151, 152, 152, 152, 152, 153, 153, 153, 153, 154, 154, 154, 154, 155, 155, 155, 155, 156, 156, 156, 156, 157, 157, 157, 157, 158, 158, 158, 158, 159, 159, 159, 159, 160, 160, 160, 160, 161, 161, 161, 161, 162, 162, 162, 162, 162, 163, 163, 163, 163, 164, 164, 164, 164, 165, 165, 165, 165, 166, 166, 166, 166, 167, 167, 167, 167, 168, 168, 168, 168, 169, 169, 169, 169, 170, 170, 170, 170, 171, 171, 171, 171, 172, 172, 172, 172, 173, 173, 173, 173, 174, 174, 174, 174, 175, 175, 175, 175, 176, 176, 176, 176, 177, 177, 177, 177, 178, 178, 178, 178, 178, 179, 179, 179, 179, 180, 180, 180, 180, 181, 181, 181, 181, 182, 182, 182, 182, 183, 183, 183, 183, 184, 184, 184, 184, 185, 185, 185, 185, 186, 186, 186, 186, 187, 187, 187, 187, 188, 188, 188, 188, 189, 189, 189, 189, 190, 190, 190, 190, 191, 191, 191, 191, 192, 192, 192, 192, 193, 193, 193, 193, 194, 194, 194, 194, 195, 195, 195, 195, 195, 196, 196, 196, 196, 197, 197, 197, 197, 198, 198, 198, 198, 199, 199, 199, 199, 200, 200, 200, 200, 201, 201, 201, 201, 202, 202, 202, 202, 203, 203, 203, 203, 204, 204, 204, 204, 205, 205, 205, 205, 206, 206, 206, 206, 207, 207, 207, 207, 208, 208, 208, 208, 209, 209, 209, 209, 210, 210, 210, 210, 211, 211, 211, 211, 211, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 215, 215, 215, 215, 216, 216, 216, 216, 217, 217, 217, 217, 218, 218, 218, 218, 219, 219, 219, 219, 220, 220, 220, 220, 221, 221, 221, 221, 222, 222, 222, 222, 223, 223, 223, 223, 224, 224, 224, 224, 225, 225, 225, 225, 226, 226, 226, 226, 227, 227, 227, 227, 227, 228, 228, 228, 228, 229, 229, 229, 229, 230, 230, 230, 230, 231, 231, 231, 231, 232, 232, 232, 232, 233, 233, 233, 233, 234, 234, 234, 234, 235, 235, 235, 235, 236, 236, 236, 236, 237, 237, 237, 237, 238, 238, 238, 238, 239, 239, 239, 239, 240, 240, 240, 240, 241, 241, 241, 241, 242, 242, 242, 242, 243, 243, 243, 243, 243, 244, 244, 244, 244, 245, 245, 245, 245, 246, 246, 246, 246, 247, 247, 247, 247, 248, 248, 248, 248, 249, 249, 249, 249, 250, 250, 250, 250, 251, 251, 251, 251

inc_hex_time:
	mov a, time_hex+0
	add a, #1
	mov time_hex+0, a
	mov a, time_hex+1
	addc a, #0 
	mov time_hex+1, a
	ret

no_transmit_longjump:
	ljmp no_transmit

; Timer 0 has the temperature control and sends data through the serial port every second
ISR_timer0:
	push psw
	push dph
	push dpl
	push acc
	push AR0
	push AR1
	push AR2
	push AR3
	push AR4
	push AR5
	push AR6
	push AR7
	push b

	clr ET0
	clr TR0

	cpl P0.0

	;-----PWM THE OVEN
	inc pwm_counter
	mov a,pwm_counter
	cjne a, #100, done_increment_pwm
		mov pwm_counter, #0
		setb pwm
		sjmp done_pwm
	done_increment_pwm:
	mov a,pwm_counter
	cjne a,#10,done_pwm
		clr pwm
	done_pwm:
	;-----END PWM THE OVEN
	mov c,pwm
	clr a
	rlc a
	mov ledrc, a

	inc hundred_counter
	mov a, hundred_counter
	cjne a, #100, no_transmit_longjump
	clr a
	mov hundred_counter, a

	lcall read_temperature
	mov x+0, temperature+0
	mov x+1, temperature+1
	lcall hex2bcd
	lcall SendTemp
	lcall getString	;stores string in buffer variable
	lcall parseString
	jnb t0f, no_transmit

	lcall Temperature2ASCII

	mov a,state_code
	cjne a,#2,check_reflow_state
	lcall inc_hex_time

	check_reflow_state:
	mov a,state_code
	cjne a,#4,done_increment_time
	lcall inc_hex_time

	done_increment_time:

	;Increments the time in ASCII and displays it.
	mov a, time+0
	add a, #1
	mov time+0, a
	cjne a, #3AH, done_adding
	mov time+0, #30H
	mov a, time+1
	add a, #1
	mov time+1, a
	cjne a, #3AH, done_adding
	mov time+1, #30H
	mov a, time+2
	add a, #1
	mov time+2, a
	cjne a, #3AH, done_adding
	mov time+2, #30H

done_adding:
	LCD_Line_mac(#0C0H)
	lcall WriteLittleT
	LCD_put_mac(time+2)
	LCD_put_mac(time+1)
	LCD_put_mac(time+0)
	LCD_put_mac(#'s')
	LCD_Line_mac(#80H)

no_transmit:
	mov a, state_code
;THIS IS FOR TURNING THE SSR ON AND OFF DEPENDING ON WHICH STATE THE CONTROLLER IS IN
check_state_0:
	cjne a, #STATE_CHECK_INPUTS, check_state_1
	setb SSR_CON ;toaster oven needs to be off
	clr LED_CON
	sjmp heating_finished
check_state_1:
	cjne a, #STATE_RAMP_TO_SOAK, check_state_2
	jb oven_off_flag, state_1_oven_off
	clr SSR_CON
	setb LED_CON
	sjmp heating_finished
	state_1_oven_off:
	setb SSR_CON
	clr LED_CON
	sjmp heating_finished
check_state_2:
	cjne a, #STATE_SOAK, check_state_3
	; on for 1/10 s off for 9/10
	mov c,pwm
	cpl c
	mov SSR_CON,c
	mov c, pwm
	mov LED_CON,c
	sjmp heating_finished
check_state_3:
	cjne a, #STATE_RAMP_TO_REFLOW, check_state_4
	jb oven_off_flag, state_3_oven_off
	clr SSR_CON
	setb LED_CON
	sjmp heating_finished
	state_3_oven_off:
	setb SSR_CON
	clr LED_CON
	sjmp heating_finished
check_state_4:
	cjne a, #STATE_REFLOW, check_state_5
	; on for 1/10 s off for 9/10
	mov c,pwm
	cpl c
	mov SSR_CON,c
	mov c, pwm
	mov LED_CON,c
	sjmp heating_finished
check_state_5:
	cjne a, #STATE_COOLDOWN, heating_finished
	setb SSR_CON
	clr LED_CON
heating_finished:
	mov TH0, #high(TIMER0_RELOAD)
	mov TL0, #low(TIMER0_RELOAD)
	setb TR0
	setb ET0

	pop b
	pop AR7
	pop AR6
	pop AR5
	pop AR4
	pop AR3
	pop AR2
	pop AR1
	pop AR0
	pop acc
	pop dpl
	pop dph
	pop psw
	reti

ISR_timer1:	; Timer 1 creates a square wave for the buzzer
	clr TR1
	cpl BUZZER_OUT
	mov TH1, #high(TIMER1_RELOAD)
	mov TL1, #low(TIMER1_RELOAD)
	setb TR1
	reti

InitTimers:	;Initialize timer 1 and 0 as 16 bit timers
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0,1 and clear overflow flags
	clr TR1
	clr TF0
	clr TF1
	mov TH0, #high(TIMER0_RELOAD)
	mov TL0, #low(TIMER0_RELOAD)
	mov TH1, #high(TIMER1_RELOAD)
	mov TL1, #low(TIMER1_RELOAD)
	setb ET0
	setb TR0
	setb ET1 
	setb TR1
	ret

Display:
	mov dptr, #myLUT
	; Display Digit 0
	mov A, bcd+0
	anl a, #0fh
	movc A, @A+dptr
	mov HEX0, A
	; Display Digit 1
	mov A, bcd+0
	swap a
	anl a, #0fh
	movc A, @A+dptr
	mov HEX1, A
	; Display Digit 2
	mov A, bcd+1
	anl a, #0fh
	movc A, @A+dptr
	mov HEX2, A
	ret

; Gets the digital value from the thermocouple and converts to a temperature
; Gets the digital value from the LM335 and converts to a temperature
; The sum of the two temperatures is the temperature of the PCB
read_temperature:
	lcall convert_cold_temperature
	lcall convert_hot_temperature
	mov a, hot_junction
	add a, cold_junction
	mov temperature, a
	mov temperature+1, #0
	ret

Temperature2ASCII:	; Write the current oven temperature to the LCD
	mov x+0, temperature+0
	mov x+1, temperature+1
	lcall hex2bcd
	lcall WriteTemp

	mov a, bcd+1
	anl a, #00001111B
	add a, #30H
	mov r7, a
	LCD_put_mac(r7)

	mov a, bcd+0
	anl a, #11110000B
	swap a
	add a, #30H
	mov r7, a
	LCD_put_mac(r7)

	mov a, bcd+0
	anl a, #00001111B
	add a, #30H
	mov r7, a
	LCD_put_mac(r7)

	LCD_put_mac(#'C')
	ret

; This subroutine is for reading the temperature
; from the LM335 so that the cold junction
; temperature is known
convert_cold_temperature:
	mov b, #3  ; Read channel 3
	lcall Read_ADC_Channel

	mov x+1, R7
	mov x+0, R6

	; The temperature can be calculated as (ADC*500/1024)-273 (may overflow 16 bit operations)
	; or (ADC*250/512)-273 (may overflow 16 bit operations)
	; or (ADC*125/256)-273 (may overflow 16 bit operations)
	; or (ADC*62/256)+(ADC*63/256)-273 (Does not overflow 16 bit operations!)

	Load_y(62)
	lcall mul16
	mov R4, x+1

	mov x+1, R7
	mov x+0, R6

	Load_y(63)
	lcall mul16
	mov R5, x+1

	mov x+0, R4
	mov x+1, #0
	mov y+0, R5
	mov y+1, #0
	lcall add16

	Load_y(273)
	lcall sub16

	;x contains the temperature
	mov a, x
	mov cold_junction, a

	ret

; Converts digital value from ADC into a temperature by using a look up table
; Digital value is stored in x
convert_hot_temperature:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel

	mov x+1, R7
	mov x+0, R6

	mov dptr, #thermocouple_look_up_table
	mov a, x+0
	add a, dpl
	mov dpl, a
	mov a, x+1		; Sets high to the first 8-bits of x
	addc a, dph 		; Sets low to the last 8-bits of x
	mov dph, a

	clr a
	movc a, @a+dptr		; Selects the first 8-bits to display
	mov hot_junction, a
	ret

Wait200ms: ; Currently used for debouncing the switches
	mov R2, #70
Wait200ms_L3: mov R1, #125
Wait200ms_L2: mov R0, #125
Wait200ms_L1: djnz R0, Wait200ms_L1
	djnz R1, Wait200ms_L2
	djnz R2, Wait200ms_L3
	ret

Wait50ms: ; Currently used for debouncing the switches
	mov R2, #17
Wait50ms_L3: mov R1, #125
Wait50ms_L2: mov R0, #125
Wait50ms_L1: djnz R0, Wait50ms_L1
	djnz R1, Wait50ms_L2
	djnz R2, Wait50ms_L3
	ret

WaitHalfSec:
	mov R2, #90
L3: mov R1, #250
L2: mov R0, #250
L1: djnz R0, L1 
	djnz R1, L2
	djnz R2, L3
	ret

DecrementVal:	;Decrements the val/time in ASCII and displays it.
	clr a
	clr c
	mov a, val+0
	subb a, #1H
	mov val+0, a
	cjne a, #2FH, I1
	mov val+0, #39H
	clr c
	mov a, val+1
	subb a, #1H
	mov val+1, a
	cjne a, #2FH, I1
	mov val+1, #39H
	clr c
	mov a, val+2
	subb a, #1H
	mov val+2, a
	cjne a, #2FH, I1
	mov val+2, #39H
I1:	ret

IncrementVal:	;Increments the val/time in ASCII and displays it
	clr a
	mov a, val+0
	add a, #1H
	mov val+0, a
	cjne a, #3AH, I0
	mov val+0, #30H
	mov a, val+1
	add a, #1H
	mov val+1, a
	cjne a, #3AH, I0
	mov val+1, #30H
	mov a, val+2
	add a, #1H
	mov val+2, a
	cjne a, #3AH, I0
	mov val+2, #30H
I0:	ret

CheckButtons_mac Mac ; Macro that checks state of the keys
	lcall %0
	lcall %5
	lcall WriteValue
	LCD_put_mac(%3)
%1:	jb KEY.3, %2
	lcall Wait50ms
	lcall IncrementVal
	lcall %0
	lcall WriteValue
	LCD_put_mac(%3)
	jnb KEY.3,%1
%2:	jb KEY.2, %4
	lcall Wait50ms
	lcall DecrementVal
	lcall %0
	lcall WriteValue
	LCD_put_mac(%3)
	jnb KEY.2,%2
%4: lcall Wait50ms
	lcall Wait200ms
endmac

ClearVal:
	mov val+0, #30H
	mov val+1, #30H
	mov val+2, #30H
	ret

; Should get inputs from the user for the reflow profile to be used
; SW17 determines whether the DE2 gets info from computer or from switches
check_inputs:
	;lcall CheckKillSwitch
	lcall WriteHEXOff
	mov state_code, #0
	setb LEDRA.0
	lcall WriteSelect

wait_for_device_select:	; Determines whether to use Android or DE2 inputs
	mov val+2, #31H
	jnb KEY.2, wait_for_DE2
	jnb KEY.3, input_serial
	jb KEY.2, wait_for_device_select
	jb KEY.3, wait_for_device_select

input_serial:	; Obtains values from Java and inputs into state variables
	mov soak_temp+0, temp_soak_temp+0
	mov soak_temp+1, temp_soak_temp+1
	mov soak_temp+2, temp_soak_temp+2
	mov soak_time+0, temp_soak_time+0
	mov soak_time+1, temp_soak_time+1
	mov soak_time+2, temp_soak_time+2
	mov reflow_temp+0, temp_reflow_temp+0
	mov reflow_temp+1, temp_reflow_temp+1
	mov reflow_temp+2, temp_reflow_temp+2
	mov reflow_time+0, temp_reflow_time+0
	mov reflow_time+1, temp_reflow_time+1
	mov reflow_time+2, temp_reflow_time+2	
	ljmp wait_for_start_btn
	
wait_for_DE2:
	lcall clearscreen
wait_for_soak_temp:	; Gets user input for Soak Temp
	lcall WaitHalfSec
	CheckButtons_mac(WriteSetSoakTemp, S0, S1, #'C', W4, WriteTemp)
	mov soak_temp+0, val+0
	mov soak_temp+1, val+1
	mov soak_temp+2, val+2
W0:	jb KEY.1, wait_for_soak_temp
	jnb KEY.1, $

	lcall ClearVal
	mov val+1, #33H

wait_for_soak_time:	; Gets user input for Soak Time
	CheckButtons_mac(WriteSetSoakTime, S2, S3, #'s', W5, WriteTime)
	mov soak_time+0, val+0
	mov soak_time+1, val+1
	mov soak_time+2, val+2
W1:	jb KEY.1, wait_for_soak_time
	jnb KEY.1, $

	lcall ClearVal
	mov val+2, #32H

wait_for_reflow_temp:	; Gets user input for Reflow Temp
	CheckButtons_mac(WriteSetReflowTemp, S4, S5, #'C', W6, WriteTemp)
	mov reflow_temp+0, val+0
	mov reflow_temp+1, val+1
	mov reflow_temp+2, val+2
W2:	jb KEY.1, wait_for_reflow_temp
	jnb KEY.1, $

	lcall ClearVal
	mov val+1, #33H

wait_for_reflow_time:	; Gets user input for Reflow Time
	CheckButtons_mac(WriteSetReflowTime, S6, S7, #'s', W7, WriteTime)
	mov reflow_time+0, val+0
	mov reflow_time+1, val+1
	mov reflow_time+2, val+2
W3:	jb KEY.1, wait_for_reflow_time
	jnb KEY.1, $

	lcall ClearVal
	lcall ClearScreen

wait_for_start_btn:
	lcall WriteAskToStart

	; Converts variables in ascii to hex
	clr c
	mov a, soak_temp+0
	subb a, #30H
	anl a, #00001111B
	mov bcd+0, a

	clr c
	mov a, soak_temp+1
	subb a, #30H
	swap a
	anl a, #11110000B
	orl a, bcd+0
	mov bcd+0, a

	clr c
	mov a, soak_temp+2
	subb a, #30H
	anl a, #00001111B
	mov bcd+1, a

	mov bcd+2, #00000000B
	lcall bcd2hex
	mov soak_temp_hex+0, x+0
	mov soak_temp_hex+1, x+1

	clr c
	mov a, reflow_temp+0
	subb a, #30H
	anl a, #00001111B
	mov bcd+0, a

	clr c
	mov a, reflow_temp+1
	subb a, #30H
	swap a
	anl a, #11110000B
	orl a, bcd+0
	mov bcd+0, a

	clr c
	mov a, reflow_temp+2
	subb a, #30H
	anl a, #00001111B
	mov bcd+1, a

	mov bcd+2, #00000000B
	mov x+0, #0H
	mov x+1, #0H
	lcall bcd2hex
	mov reflow_temp_hex+0, x+0
	mov reflow_temp_hex+1, x+1

	clr c
	mov a, soak_time+0
	subb a, #30H
	anl a, #00001111B
	mov bcd+0, a

	clr c
	mov a, soak_time+1
	subb a, #30H
	swap a
	anl a, #11110000B
	orl a, bcd+0
	mov bcd+0, a

	clr c
	mov a, soak_time+2
	subb a, #30H
	anl a, #00001111B
	mov bcd+1, a

	mov bcd+2, #00000000B
	lcall bcd2hex
	mov soak_time_hex+0, x+0
	mov soak_time_hex+1, x+1

	clr c
	mov a, reflow_time+0
	subb a, #30H
	anl a, #00001111B
	mov bcd+0, a

	clr c
	mov a, reflow_time+1
	subb a, #30H
	swap a
	anl a, #11110000B
	orl a, bcd+0
	mov bcd+0, a

	clr c
	mov a, reflow_time+2
	subb a, #30H
	anl a, #00001111B
	mov bcd+1, a

	mov bcd+2, #00000000B
	lcall bcd2hex
	mov reflow_time_hex+0, x+0
	mov reflow_time_hex+1, x+1

	mov x+0, soak_temp_hex+0
	mov x+1, soak_temp_hex+1
	lcall hex2bcd
	lcall display
wait_for_start_btn_loop:
	lcall Wait50ms
	jb KEY.1, wait_for_start_btn_loop
	lcall WriteTequals0
	lcall ClearHEX
	sjmp recieved_inputs
recieved_inputs:
	ret

; Oven should be on the entire time. stays in the loop until correct temperature is attained
ramp_to_soak:
	setb t0f
	mov state_code, #1
	setb LEDRA.1
	lcall WriteRampToSoak

ramp_to_soak_loop:
	lcall CheckKillSwitch
	mov x+0, soak_temp_hex+0
	mov x+1, soak_temp_hex+1
	lcall hex2bcd
	lcall display
	
	lcall wait200ms
	mov x+0, temperature+0
	mov x+1, temperature+1
	mov y+0, soak_temp_hex+0
	mov y+1, soak_temp_hex+1
	lcall x_gteq_y
	jnb mf, test_temp_ramp_soak
	mov state_code, #2
test_temp_ramp_soak:
	Load_Y(25)
	lcall add16
	mov y+0, soak_temp_hex+0
	mov y+1, soak_temp_hex+1
	lcall x_gteq_y
	jnb mf, test_state_ramp_soak
	setb oven_off_flag
	test_state_ramp_soak: 
	mov a, state_code
	cjne a, #2, ramp_to_soak_loop
A1:	ret

; Keeps temperature at specified level
; Stays on for user set soak time (MIN TO MAX)
; PWM: keeps oven on for 1/10 second and off for 9/10 second
soak:
	mov time_hex+0,#0
	mov time_hex+1,#0
	mov state_code, #2
	clr oven_off_flag
	setb LEDRA.2
	lcall WriteSoakingStage
soak_loop:
	lcall CheckKillSwitch
	mov x+0, soak_time_hex+0
	mov x+1, soak_time_hex+1
	lcall hex2bcd
	lcall display
	
	lcall Wait200ms
	mov x+0, time_hex+0
	mov x+1, time_hex+1
	mov y+0, soak_time_hex+0
	mov y+1, soak_time_hex+1
	clr c
	mov mf, c
	lcall x_gteq_y
	jnb mf, test_state_soak
	mov state_code, #3

	test_state_soak:
	mov a, state_code
	cjne a, #3, soak_loop
A2:	ret

; Oven should stay on the entire time
; until desired reflow temp is acheived
; (Max - 235 deg C)
ramp_to_reflow:
	mov state_code, #3
	setb LEDRA.3
	lcall WriteRampToReflow
ramp_to_reflow_loop:
	lcall CheckKillSwitch
	mov x+0, reflow_temp_hex+0
	mov x+1, reflow_temp_hex+1
	lcall hex2bcd
	lcall display
	
	lcall wait200ms
	mov x+0, temperature+0
	mov x+1, temperature+1
	mov y+0, reflow_temp_hex+0
	mov y+1, reflow_temp_hex+1
	lcall x_gteq_y
	jnb mf, test_temp_ramp_reflow
	mov state_code, #4
	test_temp_ramp_reflow:
	Load_Y(5)
	lcall add16
	mov y+0, reflow_temp_hex+0
	mov y+1, reflow_temp_hex+1
	lcall x_gteq_y
	jnb mf, test_state_ramp_reflow
	setb oven_off_flag
	test_state_ramp_reflow: 
	mov a, state_code
	cjne a, #4, ramp_to_reflow_loop
A3:	ret

; Maintain reflow temp for preset reflow time
; Max time: 45 s
; On for 1/10 second, off for 9/10
reflow:
	mov time_hex+0,#0
	mov time_hex+1,#0
	mov state_code, #4
	clr oven_off_flag
	setb LEDRA.4
	lcall WriteReflow
reflow_loop:
	lcall CheckKillSwitch
	mov x+0, reflow_time_hex+0
	mov x+1, reflow_time_hex+1
	lcall hex2bcd
	lcall display

	lcall Wait200ms
	mov x+0, time_hex+0
	mov x+1, time_hex+1
	mov y+0, reflow_time_hex+0
	mov y+1, reflow_time_hex+1
	clr c
	mov mf, c
	lcall x_gteq_y
	jnb mf, test_state_reflow
	mov state_code, #5

	test_state_reflow:
	mov a, state_code
	cjne a, #5, reflow_loop
A4:	ret

cooldown:	; Turns off oven
	mov state_code, #5
	lcall WriteHEXOff
cooldown_loop:
	lcall CheckKillSwitch
	lcall WriteCooldown
	lcall WriteOpenDoor     ;NEEDS TO TELL USER THAT IT IS OK TO OPEN THE DOOR ONCE TEMP GOES BELOW 50 DEG C
	mov x+0, temperature+0
	mov x+1, temperature+1
	Load_Y(50)
	lcall x_lteq_y
	jnb mf, cooldown_loop
	clr t0f
	lcall ClearScreen
	lcall WriteComplete
A5:	ret	

short_beep:	
	setb TR1
	lcall WaitHalfSec
	lcall WaitHalfSec
	clr TR1
	clr BUZZER_OUT
	ret

long_beep:
	setb TR1
	lcall WaitHalfSec
	lcall WaitHalfSec
	lcall WaitHalfSec
	lcall WaitHalfSec
	lcall WaitHalfSec
	lcall WaitHalfSec
	clr TR1
	clr BUZZER_OUT
	ret

end_beeps:
	mov R7, #6
end_beeps_loop:	
	setb TR1
	lcall WaitHalfSec
	clr TR1
	lcall WaitHalfSec
	djnz R7, end_beeps_loop
	clr BUZZER_OUT
	ret

CheckKillSwitch:
	jnb SWA.0, K0
	jb SWA.0, MyProgram
K0:	ret

MyProgram:
	mov sp, #07FH
	clr a
	mov LEDG,  a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov P0MOD, #0FFH
	mov P1MOD, #00101000B
	mov P2MOD, #00000010B
	mov P3MOD, #0FFH
	setb CE_ADC

	lcall InitLCD
	lcall Init_SPI
	lcall InitTimers
	lcall InitSerialPort

	setb EA
	clr TR1
	clr t0f
	clr BUZZER_OUT
	clr oven_off_flag

	mov time+0, #30H
	mov time+1, #30H
	mov time+2, #30H
	mov val+0, #30H
	mov val+1, #30H
	mov val+2, #30H
	mov time_hex+0, #0
	mov time_hex+1, #0
	;----Some other variable initializations:
	mov pwm_counter,#0
	;----End initializations
	lcall WriteTequals0

Forever:
	lcall check_inputs
	lcall short_beep
	lcall ramp_to_soak
	lcall short_beep
	lcall soak
	lcall short_beep
	lcall ramp_to_reflow
	lcall short_beep
	lcall reflow
	lcall long_beep
	lcall cooldown
	lcall end_beeps
	sjmp $
END