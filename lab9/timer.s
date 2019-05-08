;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; timer.s
; This module handles the timer interrupt and fires various system timers

; Every 1 second - fire clock update
; Every 25ms - Debounce (tick)
; Every 1ms - Check piob

timer_inc       EQU     1                         ; 1ms timer
timer_max       EQU     0xFF
timer_s_1s      EQU     (1000 / timer_inc)        ; how many steps before 1s
timer_s_25ms    EQU     (25/timer_inc)            ; how many steps before 25ms

timer_1s_c      DEFW    0                         ; counters to determine when to fire
timer_25ms_c    DEFW    0


Timer_update    STMFD   SP!, {LR, R0-R3}
                BL      Timer_ms                  ; Fire every tick
                ADR     R0, timer_25ms_c          ; determine if 25ms has passed
                LDR     R1, [R0]
                CMP     R1, #timer_s_25ms
                ADDNE   R1, R1, #1                ; add 1 to count
                MOVEQ   R1, #0                    ; reset if equal
                STR     R1, [R0]
                BLEQ    Timer_25ms

                ADR     R0, timer_1s_c            ; determine if 1s has passed
                LDR     R1, [R0]
                CMP     R1, #timer_s_1s
                ADDNE   R1, R1, #1                ; add 1 to count
                MOVEQ   R1, #0                    ; reset if equal
                STR     R1, [R0]
                BLEQ    Timer_sec

                MOV     R1, #base_adr             ; need to set the next interrupt
                LDRB    R0, [R1, #timer_ofs]
                ADD     R0, R0, #timer_inc
                CMP     R0, #timer_max
                BLO     t_do_compare
                SUB     R0, R0, #timer_max
t_do_compare    STRB    R0, [R1, #timer_c_ofs]
                LDMFD   SP!, {PC, R0-R3}


; Fired every 1s, include the functions we want to happen in here
Timer_sec       STMFD   SP!, {LR}
                BL      Clock_update
                BL      Alarm_check
                LDMFD   SP!, {PC}

; Fired every 25ms, include the functions we want to happen in here
Timer_25ms      STMFD   SP!, {LR}
                BL      Btn_debounce
                BL      Key_debounce
                LDMFD   SP!, {PC}

; Fired every 1ms
Timer_ms        STMFD   SP!, {LR}
                BL      Btn_a_check
                BL      Keyboard_scan
                LDMFD   SP!, {PC}
