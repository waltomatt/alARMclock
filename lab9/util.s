;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; util.s
; This module contains functions which have no other place

; Divide10 procedure
; R0 = number to divide
; returns the divided value in R0, remainder in R1
divisor10       DEFW    &1999999A                 ; ~2^32/10
Divide10        STMFD   SP!, {LR, R2, R3}
                ADR     R1, divisor10
                LDR     R1, [R1]
                UMULL   R2, R3, R0, R1            ; we're essentially doing n * 2^32/1000 then dividing by 2^32
                MOV     R1, #10
                MUL     R1, R3, R1                ; mul back by 10
                SUB     R1, R0, R1                ; remainder into r1
                MOV     R0, R3                    ; move divided value to R0
                LDMFD   SP!, {PC, R2, R3}
