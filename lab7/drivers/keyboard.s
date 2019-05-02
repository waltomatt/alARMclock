;---------------------------------------------------------------------------
;       Matt Walton
;       Version 1.0
;       19th March 2019
;
;       This is an implementation for a matrix keyboard driver
;
;---------------------------------------------------------------------------

; keyboard.s

k_fpga_adr          EQU     &20000000
k_col_start         EQU     &80
k_row_start         EQU     &1
k_col_count         EQU     &3
k_row_count         EQU     &4

k_max_index         EQU     k_col_count * k_row_count -1

k_ascii             DEFB    &31                  ; ascii table for keyboard chars
                    DEFB    &32
                    DEFB    &33
                    DEFB    &34
                    DEFB    &35
                    DEFB    &36
                    DEFB    &37
                    DEFB    &38
                    DEFB    &39
                    DEFB    &2a
                    DEFB    &30
                    DEFB    &23

k_last_key          DEFB    -1

k_bounce_array      DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0
                    DEFB    0

                    ALIGN   4
; Method that loops through the keyboard and updates the keys status in the bounce array
; when the key reads FF then we're pressed!

Scan_keyboard       STMFD       SP!, {LR, R1-R4}
                    MOV         R1, #k_fpga_adr
                    MOV         R0, #&1F
                    STRB        R0, [R1, #3]        ; set the ctrl reg
                    MOV         R2, #0              ; R2 stores col

k_scan_col          MOV         R0, #k_col_start
                    MOV         R3, #0              ; R3 stores row
                    MOV         R0, R0 LSR R2
                    STRB        R0, [R1, #2]        ; enable the column
                    LDRB        R4, [R1, #2]        ; get the data
                    SUBS        R4, R4, R0          ; sub the column
k_scan_row          MOV         R0, #k_row_start
                    MOV         R0, R0 LSL R3
                    CMP         R0, R4
                    MOVEQ       R0, #1              ; 1 if fired
                    MOVNE       R0, #0              ; 0 if not
                    BL          k_Update_key
                    ADD         R3, R3, #1
                    CMP         R3, #k_row_count    ; check if we done all rows
                    BNE         k_scan_row
                    ADD         R2, R2, #1
                    CMP         R2, #k_col_count
                    BNE         k_scan_col
                    LDMFD       SP!, {PC, R1-R4}    ; return

k_Update_key        STMFD       SP!, {LR, R0-R3}
                    MOV         R1, #k_col_count
                    MUL         R1, R1, R3          ; index = row * col_count + col
                    ADD         R1, R1, R2
                    CMP         R1, #k_max_index    ; check if valid index
                    BGT         k_upd_done
                    ADR         R2, k_bounce_array
                    LDRB        R3, [R2, R1]
                    MOV         R3, R3 LSL #1       ; shift left 1
                    ADD         R3, R3, R0          ; add 1/0
                    CMP         R3, #&FF            ; check if key is fully depressed
                    MOVEQ       R0, #0              ; reset if pressed fully
                    STRB        R3, [R2, R1]        ; store back
                    BNE         k_upd_done
                    ADR         R2, k_last_key
                    STRB        R1, [R2]            ; update last key entry
k_upd_done          LDMFD       SP!, {PC, R0-R3}    ; return


; SVC routine to get a pressed key
; returns the ascii code in R0, or 0 if no key pressed

Get_last_key        STMFD       SP!, {LR, R1, R2}
                    ADR         R2, k_last_key
                    LDRB        R0, [R2]            ; load last key
                    CMP         R0, #&FF
                    MOVEQ       R0, #0
                    BEQ         k_glk_done
k_glk_got           ADR         R1, k_ascii         ; get the ascii value now
                    LDRB        R0, [R1, R0]
                    MOV         R1, #-1              ; reset last key
                    STRB        R1, [R2]
k_glk_done          LDMFD       SP!, {LR, R1, R2}
                    BAL         svc_done
