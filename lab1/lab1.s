; COMP22712 - Exercise 1
; Matt Walton, 2019

;     Left                  Right
; R   00000100 (0x4)        01000000 (0x40)
; A   00000010 (0x2)        00100000 (0x20)
; G   00010001 (0x1)        00010001 (0x10)


Main        ADR   SP, Stack           ; initiailise stack pointer
            ADD   SP, SP, #8          ; our stack is only 2 words
            LDR   R3, =&10000000      ;  move the address of the LEDs into R2, going to keep this register for our address
            MOV   R1, #0              ; want to reset all the lights
            STRB  R1, [R3]            ; store back

State_0     ORR   R1, R1, #&4         ; turn on the left red light
            ORR   R1, R1, #&40        ; Turn on the right red light
            STRB  R1, [R3]            ; store back
            MOV   R0, #1              ; 1 delay
            BL    Do_delay

State_1     ORR   R1, R1, #&2         ; turn on left ambre
            STRB  R1, [R3]            ; store back
            BL    Do_delay            ; 1 delay

State_2     BIC   R1, R1, #&4         ; turn off red left
            BIC   R1, R1, #&2         ; turn off amber left
            ORR   R1, R1, #&1         ; turn on green left
            STRB  R1, [R3]            ; store back
            MOV   R0, #3              ; delay 3 this time
            BL    Do_delay

State_3     BIC   R1, R1, #&1         ; turn off left green
            ORR   R1, R1, #&2         ; turn on amber left
            STRB  R1, [R3]            ; store back
            MOV   R0, #1              ; delay 1
            BL    Do_delay

State_4     BIC   R1, R1, #&2         ; turn off amber left
            ORR   R1, R1, #&4         ; turn on red left
            STRB  R1, [R3]            ; store back
            BL    Do_delay            ; delay for 1 again

State_5     ORR   R1, R1, #&20        ; turn on right amber
            STRB  R1, [R3]            ; store back
            BL    Do_delay            ; delay for 1 again

State_6     BIC   R1, R1, #&40        ; turn off right red
            BIC   R1, R1, #&20        ; turn off right amber
            ORR   R1, R1, #&10        ; turn on right green
            STRB  R1, [R3]            ; store back
            MOV   R0, #3              ; delay for 3
            BL    Do_delay

State_7     BIC   R1, R1, #&10        ; turn off right green
            ORR   R1, R1, #&20        ; turn on right amber
            STRB  R1, [R3]            ; store back
            MOV   R0, #1              ; delay for 1
            BL    Do_delay

            BAL   Main                ; restart sequence

; Do_delay subroutine, R0 = delay
Do_delay    STMFD SP!, {R1, R2}       ; push working registers
            LDR   R1, =&30000         ; how many loops for one cycle in delay
            MUL   R1, R1, R0          ; multiply the amount of loops by the delay specified
            MOV   R2, #0              ; r2 will be the counter in the delay cycle

Delay_loop  ADD   R2, R2, #1          ; add 1 to our counter
            CMP   R2, R1              ; check if we've delayed enough yet
            BLT   Delay_loop          ; if not, keep looping
            LDMFD SP!, {R1, R2}       ; pop our working registers
            MOV   PC, LR              ; return


Stack       DEFS  2                   ; define our Stack
