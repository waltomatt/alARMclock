;---------------------------------------------------------------------------
;       EX4: System calls
;       Matt Walton
;       Version 1.0
;       18th February 2019
;
;       This program implements my previous code for writing to an LCD
;       but instead making sure the driver is run in supervisor mode
;       and calls are made from user code to this via SVC calls.
;
;---------------------------------------------------------------------------

; library.s
; this provides functions to make calls to the LCD driver a bit nicer

; Procedure to write a character to the LCD using the SVC call
; R0 = character
Write_char  STMFD SP!, {LR, R1 ,R0}
            MOV   R1, R0            ; move our value at R0 to R1
            MOV   R0, #1            ; we want to write a character
            SVC   0                 ; Call our service routine
            LDMFD SP!, {PC, R1, R0}


; Procedure to send a command to the LCD controller
; R0 = cmd
Write_cmd   STMFD SP!, {LR, R1 ,R0}
            MOV   R1, R0            ; move our value at R0 to R1
            MOV   R0, #0            ; we want to send a command
            SVC   0                 ; Call our service routine
            LDMFD SP!, {PC, R1, R0}

; Procedure to write a string to the LCD
; R0 = start address of string
; The procedure will continue until a null byte string terminator is hit

Write_str   STMFD SP!, {LR, R0, R1}     ; we're using R2, and want to push the LR to the stack
            MOV   R1, R0            ; move R0 > R1
next_byte   LDRB  R0, [R1], #1      ; load our byte into R2 and increment
            CMP   R0, #0            ; are we at null byte? end of string?
            BEQ   wstr_dne

            BL    Write_char
            BAL   next_byte
wstr_dne    LDMFD SP!, {PC, R0, R1}     ; pop our registers back and branch back
