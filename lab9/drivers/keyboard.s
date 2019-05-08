;---------------------------------------------------------------------------
;       Matt Walton
;       Version 1.0
;       19th March 2019
;
;       This is an implementation for a matrix keyboard driver
;
;---------------------------------------------------------------------------

; keyboard.s


; Keys are debounced with an array of bytes
; 0xFF is stored in the array when a key is pressed and it will not allow
; further input until the value is 0.
; The values are shifted left 1 place every 25ms by the timer module
; This means there must be a minimum of 200ms between each key press

k_fpga_adr      EQU     &20000000
k_col_start     EQU     &80
k_row_start     EQU     &1
k_col_count     EQU     &3
k_row_count     EQU     &4

k_max_index     EQU     k_col_count * k_row_count -1

k_last_key      DEFB    -1

k_bounce_array  DEFB    0
                DEFB    0
                DEFB    0
                DEFB    0
                DEFB    0
                DEFB    0
                DEFB    0
                DEFB    0
                DEFB    0
                DEFB    0

k_max_val       EQU     9

                ALIGN   4

; Method that loops through the keyboard and updates the keys status in the bounce array
; when the key reads FF then we're pressed!

Keyboard_scan   STMFD   SP!, {LR, R1-R4}
                MOV     R1, #k_fpga_adr
                MOV     R0, #&1F
                STRB    R0, [R1, #3]              ; set the ctrl reg
                MOV     R2, #0                    ; R2 stores col

k_scan_col      MOV     R0, #k_col_start
                MOV     R3, #0                    ; R3 stores row
                MOV     R0, R0 LSR R2
                STRB    R0, [R1, #2]              ; enable the column
                LDRB    R4, [R1, #2]              ; get the data
                SUBS    R4, R4, R0                ; sub the column
k_scan_row      MOV     R0, #k_row_start
                MOV     R0, R0 LSL R3
                CMP     R0, R4
                MOVEQ   R0, #1                    ; 1 if fired
                MOVNE   R0, #0                    ; 0 if not
                BLEQ    Keyboard_check
                ADD     R3, R3, #1
                CMP     R3, #k_row_count          ; check if we done all rows
                BNE     k_scan_row
                ADD     R2, R2, #1
                CMP     R2, #k_col_count
                BNE     k_scan_col
                LDMFD   SP!, {PC, R1-R4}          ; return

; Fired when a key is pressed, not debounced yet
Keyboard_check  STMFD   SP!, {LR, R0-R3}
                MOV     R1, #k_col_count
                MUL     R1, R1, R3                ; index = row * col_count + col
                ADD     R1, R1, R2
                CMP     R1, #k_max_index          ; check if valid index
                BGT     k_upd_done                ; index not valid!
                ADD     R1, R1, #1                ; add 1 to get keypad value
                CMP     R1, #0xB                  ; this is the 0 value, so set accordingly
                MOVEQ   R1, #0
                CMP     R1, #k_max_val            ; we only want 0-9 for this Project
                BGT     k_upd_done
                ADR     R2, k_bounce_array        ; get the bounce status
                LDRB    R3, [R2, R1]
                CMP     R3, #0                    ; only allow continue if 0
                BNE     k_upd_done
                MOV     R3, #0xFF                 ; set the bounce
                STRB    R3, [R2, R1]
                MOV     R0, R1
                BL      Keyboard_press
k_upd_done      LDMFD   SP!, {PC, R0-R3}          ; return

; Called every 25ms to debounce
Key_debounce    STMFD   SP!, {LR, R0-R2}
                ADR     R0, k_bounce_array
                MOV     R1, #0                    ; storing the key we're debouncing
kdb_loop        LDRB    R2, [R0, R1]
                MOV     R2, R2, LSL#1             ; shift left
                STRB    R2, [R0, R1]
                ADD     R1, R1, #1
                CMP     R1, #k_max_val
                BLE     kdb_loop
                LDMFD   SP!, {PC, R0-R2}

; Called when an actual key is pressed
; inputs: R0 = key value
Keyboard_press  STMFD       SP!, {LR}
                BL          Menu_key
                LDMFD       SP!, {PC}
