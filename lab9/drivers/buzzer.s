;---------------------------------------------------------------------------
;       Matt Walton
;       Version 1.0
;       19th March 2019
;
;       This is an implementation for a very simple buzzer (on/off)
;
;---------------------------------------------------------------------------

buzzer_ofs      EQU     0                         ; located on S0 lower

Buzzer_set      STMFD   SP!, {LR, R0-R1}
                MOV     R1, #fpga_adr
                ADD     R1, R1, #buzzer_ofs
                CMP     R0, #0                    ; 0 = off, 1 = on
                MOVNE   R0, #0xFF                 ; enable buzzer
                STRB    R0, [R1]
                LDMFD   SP!, {LR, R0-R1}
                B       svc_done
