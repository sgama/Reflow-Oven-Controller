$NOLIST

CSEG

INIT_SPI:
    clr SCLK              ; For mode (0,0) SCLK is zero
	ret
	
DO_SPI_G:
	push acc
    mov R1, #0            ; Received byte stored in R1
    mov R2, #8            ; Loop counter (8-bits)
DO_SPI_G_LOOP:
    mov a, R0             ; Byte to write is in R0
    rlc a                 ; Carry flag has bit to write
    mov R0, a
    mov MOSI, c
    setb SCLK             ; Transmit
    mov c, MISO           ; Read received bit
    mov a, R1             ; Save received bit in R1
    rlc a
    mov R1, a
    clr SCLK
    djnz R2, DO_SPI_G_LOOP
    pop acc
    ret

; Channel to read passed in register b
Read_ADC_Channel:
	clr CE_ADC
	mov R0, #00000001B ; Start bit:1
	lcall DO_SPI_G
	
	mov a, b
	swap a
	anl a, #0F0H
	setb acc.7 ; Single mode (bit 7).
	
	mov R0, a ;  Select channel
	lcall DO_SPI_G
	mov a, R1          ; R1 contains bits 8 and 9
	anl a, #03H
	mov R7, a
	
	mov R0, #55H ; It doesn't matter what we transmit...
	lcall DO_SPI_G
	mov a, R1    ; R1 contains bits 0 to 7
	mov R6, a
	setb CE_ADC
	ret

SendTempSerial:
	mov dptr, #asciilut
	; Send Digit 2 (Most significant digit)
    mov A, bcd+1
    anl a, #0fh
    movc A, @A+dptr
    lcall putchar	
	
	; Send Digit 1
    mov A, bcd+0
    swap a
    anl a, #0fh
    movc A, @A+dptr
    lcall putchar
	
	; Send Digit 0
    mov A, bcd+0
    anl a, #0fh
    movc A, @A+dptr
    lcall putchar
	
    mov a,#'\r' ;newline
    lcall putchar
    mov a,#'\n'
    lcall putchar
    ret

;WaitSomeMs:
;	mov R2, #35
;WaitSomeMs_L3: mov R1, #250
;WaitSomeMs_L2: mov R0, #250
;WaitSomeMs_L1: djnz R0, WaitSomeMs_L1
;	djnz R1, WaitSomeMs_L2
;	djnz R2, WaitSomeMs_L3
;	ret
$LIST