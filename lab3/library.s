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


; Procedure to write a string to the LCD
; R1 = start address of string
; The procedure will continue until a null byte string terminator is hit

Write_str   STMFD SP!, {LR, R1}     ; we're using R2, and want to push the LR to the stack
next_byte   LDRB  R1, [R2], #1      ; load our byte into R2 and increment
            CMP   R1, #0            ; are we at null byte? end of string?
            BEQ   wstr_dne

            BL    Write_char
            BAL   next_byte
wstr_dne    LDMFD SP!, {PC, R1}     ; pop our registers back and branch back
