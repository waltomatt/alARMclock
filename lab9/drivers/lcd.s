;---------------------------------------------------------------------------
;       Matt Walton
;       Version 1.0
;       19th March 2019
;
;       This is an implementation for a LCD Driver
;
;---------------------------------------------------------------------------

lcd_cmd_clr   EQU   &1
lcd_rw        EQU   bit_2
lcd_rs        EQU   bit_1
lcd_e         EQU   bit_0
lcd_light     EQU   bit_5


; Procedure to check if the LCD is ready & wait until it is
LCD_ready     STMFD SP!, {LR, R0, R1, R2}
              MOV   R0, #base_adr               ; portA adr
              LDRB  R1, [R0, #piob_ofs]         ; load contents of port B
              ORR   R1, R1, #lcd_rw             ; set r/w bit to 1
              BIC   R1, R1, #lcd_rs             ; set RS=0
              STRB  R1, [R0, #piob_ofs]         ; write cmd to port B
wr_loop       ORR   R1, R1, #lcd_e              ; set E=1
              STRB  R1, [R0, #piob_ofs]         ; write data to port B
              LDRB  R2, [R0]                    ; read our status bytes
              BIC   R1, R1, #lcd_e              ; set E=0
              STRB  R1, [R0, #piob_ofs]         ; write command back
              AND   R2, R2, #bit_7
              SUBS  R2, R2, #bit_7
              BEQ   wr_loop                     ; we are still busy, poll again
              LDMFD SP!, {PC, R0, R1, R2}       ; pop & return

; procedure to either write a cmd or data to the lcd
; R0 (1/0) specifies the value of RS (0 - cmd, 1- data)
; R1 specifies the cmd/character
LCD_write     STMFD SP!, {LR, R2, R3}
              BL    LCD_ready                   ; wait for lcd to be ready
              MOV   R2, #base_adr               ; load adr of port A into R2
              LDRB  R3, [R2, #piob_ofs]         ; load ctrl byte to r3
              BIC   R3, R3, #(lcd_rw OR lcd_rs) ; set RW=0 & RS=0 (we're writing)
              ORR   R3, R3, R0 lsl #1           ; set RS=R0
              STRB  R3, [R2, #piob_ofs]         ; store back in port B
              STRB  R1, [R2]                    ; store our data
              ORR   R3, R3, #lcd_e              ; set E=1
              STRB  R3, [R2, #piob_ofs]         ; store back
              BIC   R3, R3, #lcd_e              ; set E=0
              STRB  R3, [R2, #piob_ofs]         ; store back
              LDMFD SP!, {LR, R2, R3}
              B     svc_done

; procedure to set the LCD backlight to on/off
; R0 specifies 0 for off and 1 for on

LCD_set_light STMFD SP!, {LR, R1, R2}
              MOV   R1, #base_adr
              LDRB  R2, [R1, #piob_ofs]         ; load piob
              CMP   R0, #0                      ; check if we wanna turn it off
              BICEQ R2, R2, #lcd_light          ; clear bit if 0
              ORRNE R2, R2, #lcd_light          ; activate bit if 1
              STRB  R2, [R1, #piob_ofs]         ; save back
              LDMFD SP!, {LR, R1, R2}
              B     svc_done
