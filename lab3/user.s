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


cmd_clear   EQU   &1                ; clear command code

            BAL Main
stack       DEFS  128
data        DEFB  'Hello! \0'
data2       DEFB  'World!\0'

ALIGN 4

INCLUDE     driver.s
INCLUDE     library.s

Main        ADR   SP, stack         ; initiailise stack pointer
            ADD   SP, SP, #&80      ; allocate 128 bytes for the stack (cos why not)
            MOV   R1, #cmd_clear    ; going to clear the screen
            BL    Write_cmd

            ADR   R2, data          ; print our first string
            BL    Write_str

            MOV   R1, #&C0          ; move to second line?
            BL    Write_cmd

            ADR   R2, data2         ; print our second string
            BL    Write_str

            BAL   Done


Done        BAL   Done
