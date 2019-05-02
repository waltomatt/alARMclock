;---------------------------------------------------------------------------
;       Matt Walton
;       Version 1.0
;       19th March 2019
;
;       This is an implementation for a timer
;
;---------------------------------------------------------------------------

timer_ofs     EQU   &8                ; the address of the timer module
timer_c_ofs   EQU   &c                ; where we store the compare
timer_ms      DEFW  0                 ; timer's count in ms
timer_inc     EQU   5                 ; 8ms timer
timer_max     EQU   &FF

Timer_update  STMFD   SP!, {LR, R0-R2}
              ADR     R1, timer_ms              ; load current ms timer
              LDR     R0, [R1]
              ADD     R0, R0, #timer_inc        ; add the increment to the timer
              STR     R0, [R1]                  ; store back
              MOV     R1, #base_adr              ; need to set the next interrupt
              LDRB    R0, [R1, #timer_ofs]
              ADD     R0, R0, #timer_inc
              CMP     R0, #timer_max
              BLO     t_do_compare
              SUB     R0, R0, #timer_max
t_do_compare  STRB    R0, [R1, #timer_c_ofs]
              LDMFD   SP!, {PC, R0-R2}          ; done

; procudure to return the current elapsed ms since Timer_reset was called
; returns in R0
Timer_read    STMFD   SP!, {LR}
              ADR     R0, timer_ms
              LDR     R0, [R0]
              LDMFD   SP!, {LR}                 ; return
              B       svc_done

; procedure to reset the timer to 0
Timer_reset   STMFD   SP!, {LR, R0, R1}
              ADR     R0, timer_ms
              MOV     R1, #0
              STR     R1, [R0]
              LDMFD   SP!, {LR, R0, R1}
              B       svc_done
