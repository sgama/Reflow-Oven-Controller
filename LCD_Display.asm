$NOLIST

CSEG

InitLCD:
	setb LCD_ON
	clr LCD_EN                ;Default state of enable must be zero
	lcall Wait40us
	mov LCD_MOD, #0xff        ;Use LCD_DATA as output port
	clr LCD_RW                        ;Only writing to the LCD in this code.
	mov a, #0ch                        ;Display on command
	lcall LCD_command
	mov a, #38H                        ;8-bits interface, 2 lines, 5x7 characters
	lcall LCD_command
	
	lcall ClearScreen
	mov a, #80H
	ret

LCD_command:
	mov LCD_DATA, A
	clr LCD_RS
	nop
	nop
	setb LCD_EN        ;Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr LCD_EN
	ljmp Wait40us

LCD_put:
	mov LCD_DATA, A
	setb LCD_RS
	nop
	nop
	setb LCD_EN        ;Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr LCD_EN
	ljmp Wait40us

ClearScreen:                ;Clears screen
	mov a, #01H 
	lcall LCD_command        
	mov R1, #40
	lcall Clr_loop
	ret

Clr_loop:
	lcall Wait40us
	djnz R1, Clr_loop
	ret

Wait40us:
    mov R0, #149
X1: 
	nop
    nop
    nop
    nop
    nop
    nop
    djnz R0, X1        ;9 machine cycles-> 9*30ns*149=40us
    ret

LCD_put_mac Mac
	mov a, %0
	lcall LCD_put
endmac

LCD_Line_mac Mac ;80H for line 1, 0C0H for line 2
	mov a, %0
	lcall LCD_command
endmac

WriteValue:
	LCD_Line_mac(#0B4H)
	LCD_put_mac(val+2)
	LCD_put_mac(val+1)
	LCD_put_mac(val+0)
	ret

WriteTemp:
	LCD_Line_mac(#0AFH)
	LCD_put_mac(#'T')
	LCD_put_mac(#'e')
	LCD_put_mac(#'m')
	LCD_put_mac(#'p')
	LCD_put_mac(#':')
	ret

WriteTime:
	LCD_Line_mac(#0AFH)
	LCD_put_mac(#'T')
	LCD_put_mac(#'i')
	LCD_put_mac(#'m')
	LCD_put_mac(#'e')
	LCD_put_mac(#':')
	ret

WriteSetSoakTemp:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'E')
	LCD_put_mac(#'T')
	LCD_put_mac(#' ')
	LCD_put_mac(#'S')
	LCD_put_mac(#'O')
	LCD_put_mac(#'A')
	LCD_put_mac(#'K')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'E')
	LCD_put_mac(#'M')
	LCD_put_mac(#'P')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret

WriteSetSoakTime:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'E')
	LCD_put_mac(#'T')
	LCD_put_mac(#' ')
	LCD_put_mac(#'S')
	LCD_put_mac(#'O')
	LCD_put_mac(#'A')
	LCD_put_mac(#'K')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'I')
	LCD_put_mac(#'M')
	LCD_put_mac(#'E')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret

WriteSetReflowTemp:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'E')
	LCD_put_mac(#'T')
	LCD_put_mac(#' ')
	LCD_put_mac(#'R')
	LCD_put_mac(#'E')
	LCD_put_mac(#'F')
	LCD_put_mac(#'L')
	LCD_put_mac(#'O')
	LCD_put_mac(#'W')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'E')
	LCD_put_mac(#'M')
	LCD_put_mac(#'P')
	LCD_put_mac(#' ')
	ret
	
WriteSetReflowTime:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'E')
	LCD_put_mac(#'T')
	LCD_put_mac(#' ')
	LCD_put_mac(#'R')
	LCD_put_mac(#'E')
	LCD_put_mac(#'F')
	LCD_put_mac(#'L')
	LCD_put_mac(#'O')
	LCD_put_mac(#'W')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'I')
	LCD_put_mac(#'M')
	LCD_put_mac(#'E')
	LCD_put_mac(#' ')
	ret

WriteAskToStart:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'T')
	LCD_put_mac(#'A')
	LCD_put_mac(#'R')
	LCD_put_mac(#'T')
	LCD_put_mac(#' ')
	LCD_put_mac(#'R')
	LCD_put_mac(#'E')
	LCD_put_mac(#'F')
	LCD_put_mac(#'L')
	LCD_put_mac(#'O')
	LCD_put_mac(#'W')
	LCD_put_mac(#'?')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_Line_mac(#0C0H)
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret
	
WriteRampToSoak:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'R')
	LCD_put_mac(#'A')
	LCD_put_mac(#'M')
	LCD_put_mac(#'P')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'O')
	LCD_put_mac(#' ')
	LCD_put_mac(#'S')
	LCD_put_mac(#'O')
	LCD_put_mac(#'A')
	LCD_put_mac(#'K')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret
	
WriteSoakingStage:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'O')
	LCD_put_mac(#'A')
	LCD_put_mac(#'K')
	LCD_put_mac(#'I')
	LCD_put_mac(#'N')
	LCD_put_mac(#'G')
	LCD_put_mac(#' ')
	LCD_put_mac(#'S')
	LCD_put_mac(#'T')
	LCD_put_mac(#'A')
	LCD_put_mac(#'G')
	LCD_put_mac(#'E')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret
	
WriteRampToReflow:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'R')
	LCD_put_mac(#'A')
	LCD_put_mac(#'M')
	LCD_put_mac(#'P')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'O')
	LCD_put_mac(#' ')
	LCD_put_mac(#'R')
	LCD_put_mac(#'E')
	LCD_put_mac(#'F')
	LCD_put_mac(#'L')
	LCD_put_mac(#'O')
	LCD_put_mac(#'W')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret
	
WriteReflow:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'R')
	LCD_put_mac(#'E')
	LCD_put_mac(#'F')
	LCD_put_mac(#'L')
	LCD_put_mac(#'O')
	LCD_put_mac(#'W')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret

WriteCooldown:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'C')
	LCD_put_mac(#'O')
	LCD_put_mac(#'O')
	LCD_put_mac(#'L')
	LCD_put_mac(#'I')
	LCD_put_mac(#'N')
	LCD_put_mac(#'G')
	LCD_put_mac(#' ')
	LCD_put_mac(#'D')
	LCD_put_mac(#'O')
	LCD_put_mac(#'W')
	LCD_put_mac(#'N')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret

WriteLittleT:
	LCD_Line_mac(#0C0H)
	LCD_put_mac(#'t')
	LCD_put_mac(#':')
	ret

WriteTequals0:
	lcall WriteLittleT
	LCD_put_mac(time+2)
	LCD_put_mac(time+1)
	LCD_put_mac(time+0)
	LCD_put_mac(#'s')
	ret

WriteOpenDoor:
	LCD_Line_mac(#0C0H)
	LCD_put_mac(#'O')
	LCD_put_mac(#'P')
	LCD_put_mac(#'E')
	LCD_put_mac(#'N')
	LCD_put_mac(#' ')
	LCD_put_mac(#'D')
	LCD_put_mac(#'O')
	LCD_put_mac(#'O')
	LCD_put_mac(#'R')
	LCD_put_mac(#' ')
	LCD_put_mac(#'N')
	LCD_put_mac(#'O')
	LCD_put_mac(#'W')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret
	
WriteComplete:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'R')
	LCD_put_mac(#'E')
	LCD_put_mac(#'F')
	LCD_put_mac(#'L')
	LCD_put_mac(#'O')
	LCD_put_mac(#'W')
	LCD_put_mac(#' ')
	LCD_put_mac(#'C')
	LCD_put_mac(#'O')
	LCD_put_mac(#'M')
	LCD_put_mac(#'P')
	LCD_put_mac(#'L')
	LCD_put_mac(#'E')
	LCD_put_mac(#'T')
	LCD_put_mac(#'E')
	LCD_put_mac(#' ')
	LCD_Line_mac(#0C0H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'A')
	LCD_put_mac(#'F')
	LCD_put_mac(#'E')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'O')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'O')
	LCD_put_mac(#'U')
	LCD_put_mac(#'C')
	LCD_put_mac(#'H')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret

WriteSelect:
	;lcall ClearScreen
	LCD_Line_mac(#80H)
	LCD_put_mac(#'A')
	LCD_put_mac(#'N')
	LCD_put_mac(#'D')
	LCD_put_mac(#'R')
	LCD_put_mac(#'O')
	LCD_put_mac(#'I')
	LCD_put_mac(#'D')
	LCD_put_mac(#' ')
	LCD_put_mac(#'O')
	LCD_put_mac(#'R')
	LCD_put_mac(#' ')
	LCD_put_mac(#'D')
	LCD_put_mac(#'E')
	LCD_put_mac(#'2')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_Line_mac(#0C0H)
	LCD_put_mac(#'-')
	LCD_put_mac(#'K')
	LCD_put_mac(#'E')
	LCD_put_mac(#'Y')
	LCD_put_mac(#'3')
	LCD_put_mac(#'-')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#'-')
	LCD_put_mac(#'K')
	LCD_put_mac(#'E')
	LCD_put_mac(#'Y')
	LCD_put_mac(#'2')
	LCD_put_mac(#'-')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret

WriteStart:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'T')
	LCD_put_mac(#'A')
	LCD_put_mac(#'R')
	LCD_put_mac(#'T')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	ret
   
WriteSoakTemp:
	LCD_Line_mac(#80H)
	LCD_put_mac(#'S')
	LCD_put_mac(#'O')
	LCD_put_mac(#'A')
	LCD_put_mac(#'K')
	LCD_put_mac(#' ')
	LCD_put_mac(#'T')
	LCD_put_mac(#'E')
	LCD_put_mac(#'M')
	LCD_put_mac(#'P')
	LCD_put_mac(#' ')
	LCD_put_mac(#' ')
	LCD_put_mac(#':')
	ret

WriteHEXOff:
	mov HEX2, #1000000B
	mov HEX1, #0001110B
	mov HEX0, #0001110B
	ret

ClearHEX:
	mov HEX2, #11111111B
	mov HEX1, #11111111B
	mov HEX0, #11111111B
	ret
$LIST