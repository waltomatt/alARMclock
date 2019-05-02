
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

            BAL Main
data        DEFB  'Hello world!\0'

ALIGN 4

Main        ADR   SP, Stack         ; initiailise stack pointer
            ADD   SP, SP, #&c       ; our stack is only 3 words
            ADR   R2, data        ; Move the start adr of our string into memory
next_byte   LDRB  R1, [R2], #1      ; load our byte and increment
            CMP   R1, #0            ; are we at null byte? end of string?
            BEQ   Done
            BL    Write_char
            BAL   next_byte

; Procedure to write a single character (R1) to the LCD
Write_char  STMFD SP!, {R2, R3, R4}       ; push R2-4 to stack
LCD_status  ORR   R2, R0, #bit_2    ; set r/w bit to 1
            BIC   R2, R2, #bit_1    ; set RS=0
            MOV   R3, #port_B       ; copy address of port B into R3
            STRB  R2, [R3]          ; write data to port B
Enable_bus  ORR   R2, R2, #bit_0    ; set E=1
            STRB  R2, [R3]          ; write data to port B
            MOV   R4, #port_A       ; copy address of port A into R4
            LDRB  R4, [R4]          ; read our status bytes
            BIC   R2, R2, #bit_0    ; set E=0
            STRB  R2, [R3]          ; write command back
            AND   R4, R4, #bit_7
            SUBS  R4, R4, #bit_7
            BEQ   Enable_bus        ; we are still busy, poll again
            BIC   R2, R2, #bit_2    ; set r/w to 0
            ORR   R2, R2, #bit_1    ; set rs to 1
            MOV   R4, #port_A       ; copy the adr of portA into R4
            STRB  R1, [R4]          ; write our character
            ORR   R2, R2, #bit_0    ; set E=0
            STRB  R2, [R3]          ; write command back
            BIC   R2, R2, #bit_0    ; set E=1
            STRB  R2, [R3]
            LDMFD SP!, {R2, R3, R4} ; pop our registers back
            MOV   PC, LR            ; branch back


Done        BAL   Done


Stack       DEFS  3
