;---------------------------------------------------------------------------
;       EX5: Counters and Timers (part 1)
;       Matt Walton
;       Version 1.0
;       27th February 2019
;
;       This program implements a stopwatch which counts up 1 per 100ms
;       and can be controlled with the two buttons
;---------------------------------------------------------------------------


divisor         DEFW    &28F5C29              ; aprox 2^32/100
counter         DEFW    0                     ; our counter that will be inc every 100ms
stop_val        DEFW    0                     ; record the value when we stop as a 'base'

btn_low         EQU     :10000000             ; which bit for lower button
btn_high        EQU     :01000000             ; which bit for top button


Main            MOV     R3, #0                ; reset our state
                SVC     1                     ; reset timer
                ADR     R1, counter           ; reset our counter
                MOV     R0, #0
                STR     R0, [R1]
                ADR     R1, stop_val          ; reset stop val
                STR     R0, [R1]

Stopped         SVC     3
                AND     R1, R0, #btn_low
                CMP     R1, #btn_low          ; check if lower button is pressed
                BEQ     Running
                AND     R1, R0, #btn_high
                CMP     R1, #btn_high         ; check if upper button pressed
                BNE     Stopped
                SVC     1                     ; reset timer, need to check if a second passes
btn_check       SVC     3                     ; get button status
                AND     R1, R0, #btn_high
                CMP     R1, #btn_high         ; check if button still in
                BNE     Stopped
                SVC     2
                CMP     R0, #1000
                BGE     Main                  ; reset the counter, button has been in for more than a second
                B       btn_check             ; if not keep checking


Running         SVC     2                     ; get current timer value (ms)
                BL      divide100             ; divide by 100
                CMP     R0, #0                ; check if > 0
                BEQ     run_btn
                ADR     R1, stop_val          ; add our stop_val base
                LDR     R1, [R1]
                ADD     R2, R0, R1
                ADR     R1, counter
                STR     R2, [R1]
run_btn         SVC     3
                AND     R1, R0, #btn_high
                CMP     R1, #btn_high
                BNE     Running               ; loop
                ADR     R1, stop_val          ; update stop value
                STR     R2, [R1]
                B       Stopped               ; and stop


divide100       STMFD   SP!, {LR, R1, R2}
                ADR     R1, divisor           ; load our special divider
                LDR     R1, [R1]
                UMULL   R2, R0, R0, R1        ; we're essentially doing n * 2^32/100 then dividing by 2^32
                LDMFD   SP!, {PC, R1, R2}
