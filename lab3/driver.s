;-------------------------------------------------------------------------------
;         EX3: Nesting Procedure Calls
;         Matt Walton
;         Version 1.0
;         11th February 2019
;
;         This program demonstrates the use of the stack to nest Procedure
;         calls. It implements a driver for the HD44780 LCD controller
;         and provides methods to print to & control the screen.
;
;-------------------------------------------------------------------------------

; driver.s
; This contains the low level 'device driver' which is doing the direct
; bit manipulation for the LCD controller.
; This is supposed to be on the operating system 'layer'


port_A      EQU   &10000000         ; statically define our address for the data port of the LCD
port_B      EQU   &10000004         ; statically define for the control port

bit_7       EQU   &80
bit_6       EQU   &40
bit_5       EQU   &20
bit_4       EQU   &10
bit_3       EQU   &8
bit_2       EQU   &4                ; high on bit 2 (lcd r/w)
bit_1       EQU   &2                ; high on bit 1 (lcd RS)
bit_0       EQU   &1                ; high on bit 0 (lcd E)

lcd_rw      EQU   bit_2
lcd_rs      EQU   bit_1
lcd_e       EQU   bit_0

; Procedure to check if the LCD is ready & wait until it is
Wait_ready  STMFD SP!, {LR, R2, R3, R4}
            ORR   R2, R0, #lcd_rw       ; set r/w bit to 1
            BIC   R2, R2, #lcd_rs       ; set RS=0
            MOV   R3, #port_B           ; copy address of port B into R3
            STRB  R2, [R3]              ; write data to port B
wr_loop     ORR   R2, R2, #lcd_e        ; set E=1
            STRB  R2, [R3]              ; write data to port B
            MOV   R4, #port_A           ; copy address of port A into R4
            LDRB  R4, [R4]              ; read our status bytes
            BIC   R2, R2, #lcd_e        ; set E=0
            STRB  R2, [R3]              ; write command back
            AND   R4, R4, #bit_7
            SUBS  R4, R4, #bit_7
            BEQ   wr_loop               ; we are still busy, poll again
            LDMFD SP!, {PC, R2, R3, R4} ; pop & return

; Procedure to write a single character (R1) to the LCD
Write_char  STMFD SP!, {LR, R2, R3} ; push R2-4 to stack
            BL    Wait_ready        ; wait until the LCD is ready
LCD_status  BIC   R2, R0, #lcd_rw   ; set r/w to 0
            ORR   R2, R2, #lcd_rs   ; set rs to 1
            MOV   R3, #port_A       ; copy the adr of portA into R4
            STRB  R1, [R3]          ; write our character
            MOV   R3, #port_B       ; copy addr of portB into R3
            ORR   R2, R2, #lcd_e    ; set E=1
            STRB  R2, [R3]          ; write command back
            BIC   R2, R2, #lcd_e    ; set E=0
            STRB  R2, [R3]
            LDMFD SP!, {PC, R2, R3} ; pop our registers back & branch back

Write_cmd   STMFD SP!, {LR, R2, R3, R4}
            BL    Wait_ready                    ; wait for lcd to be ready
            MOV   R3, #port_B                   ; copy address of port B to R3
            LDRB  R2, [R3]                      ; load ctrl byte back into R2
            BIC   R2, R2, #(lcd_rs OR lcd_rw)   ; set RS=0, R/W = 0
            MOV   R3, #port_B
            STRB  R2, [R3]                      ; store back in port B
            MOV   R4, #port_A                   ; copy addr of port A to R4
            STRB  R1, [R4]                      ; store our cmd
            ORR   R2, R2, #lcd_e                ; set E=1
            STRB  R1, [R3]
            BIC   R2, R2, #lcd_e                ; set E=0
            STRB  R1, [R3]
            LDMFD SP!, {PC, R2, R3, R4}          ; pop registers back and branch back
