;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; button.s
; This module handles & debounces all button presses (except keyboard)
; The action button (next to screen) is checked every 1ms by the timer module

; a = action button (next to screen)
; u = up button
; d = down button

; Debouncing by only allowing fires on 0 value, setting to 1 then bit shifting
btn_a_bounce    DEFB    0
btn_u_bounce    DEFB    0
btn_d_bounce    DEFB    0
                ALIGN   4

; Shifts all the bounce values left 1 place to eventually get back to 0
Btn_debounce    STMFD   SP!, {LR, R0-R1}
                ADR     R0, btn_a_bounce          ; action button
                LDRB    R1, [R0]
                MOV     R1, R1, LSL#1
                STRB    R1, [R0]

                ADR     R0, btn_u_bounce          ; up button
                LDRB    R1, [R0]
                MOV     R1, R1, LSL#1
                STRB    R1, [R0]

                ADR     R0, btn_d_bounce          ; down button
                LDRB    R1, [R0]
                MOV     R1, R1, LSL#1
                STRB    R1, [R0]
                LDMFD   SP!, {PC, R0-R1}

; Check if the button has debounced & updates
; inputs: R0 = adr of bounce value
; returns: 1 if enough time passed, 0 if not
Btn_check       STMFD   SP!, {LR, R1}
                LDRB    R1, [R0]
                CMP     R1, #0
                MOVNE   R0, #0
                BNE     btnc_done                 ; not enough time passed
                MOV     R1, #0xFF                 ; set to FF
                STRB    R1, [R0]
                MOV     R0, #1
btnc_done       LDMFD   SP!, {PC, R1}

; Called by timer interrupt to check if middle button is pressed & debounced
Btn_a_check     STMFD   SP!, {LR, R0-R1}
                SVC     2                         ; get piob
                TST     R0, #piob_button
                BEQ     btnca_done                ; not pressed
                ADR     R0, btn_a_bounce          ; Check if enough time has passed
                BL      Btn_check
                CMP     R0, #1
                BLEQ    Btn_a_pressed             ; Call button functions
btnca_done      LDMFD   SP!, {PC, R0-R1}

; Called by top button interrupt
Btn_u_check     STMFD   SP!, {LR, R0}
                ADR     R0, btn_u_bounce          ; check if enough time passed
                BL      Btn_check
                CMP     R0, #1
                BLEQ    Btn_u_pressed
                LDMFD   SP!, {PC, R0}

; Called by bottom button interrupt
Btn_d_check     STMFD   SP!, {LR, R0}
                ADR     R0, btn_d_bounce          ; check if enough time passed
                BL      Btn_check
                CMP     R0, #1
                BLEQ    Btn_d_pressed
                LDMFD   SP!, {PC, R0}

; Button actions
; Called when middle (action) button is pressed
Btn_a_pressed   STMFD   SP!, {LR, R0}
                BL      Alarm_reset
                CMP     R0, #1                    ; Alarm_reset returns 1 to block any other btn actions
                BLNE    Menu_press
                LDMFD   SP!, {PC, R0}

; Called when up button is pressed
Btn_u_pressed   STMFD   SP!, {LR}
                BL      Menu_up
                LDMFD   SP!, {PC}

; Called when down button is pressed
Btn_d_pressed   STMFD   SP!, {LR}
                BL      Menu_down
                LDMFD   SP!, {PC}
