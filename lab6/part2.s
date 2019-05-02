;---------------------------------------------------------------------------
;       EX5: Counters and Timers (part 2)
;       Matt Walton
;       Version 1.0
;       27th February 2019
;
;       This program implements a counter which counts up 1 per second
;       and outputs onto the LCD display
;
;---------------------------------------------------------------------------


INCLUDE         lcd.s                         ; include our lcd library
counter         DEFW    0                     ; define our memory location for our counter


Main            SVC     1                     ; reset counter
counter_loop    SVC     2                     ; get counter reading
                BL      Divide1000            ; convert into seconds
                ADR     R1, counter           ; get counter address
                LDR     R1, [R1]              ; load counter value
                CMP     R0, R1                ; has the value changed?
                BEQ     counter_loop          ; no it hasn't
                ADR     R1, counter           ; our value has changed
                STR     R0, [R1]              ; store back
                BL      Print                 ; print out
                B       counter_loop          ; loop


; Print procedure
; R0 = number to print
; Pushes 5 values to stack which are the ascii digits
Print           STMFD   SP!, {LR, R0, R1, R2}
                BL      LCD_Clear             ; clear the screen
                MOV     R2, #5
print_bcd_loop  SUB     R2, R2, #1
                BL      Divide10
                ADD     R1, R1, #&30          ; add 30 for ascii
                PUSH    {R1}                  ; push to stack
                CMP     R2, #0
                BGT     print_bcd_loop        ; loop 5 times for each digit
                MOV     R2, #5
print_loop      POP     {R0}                  ; pop into R0
                BL      LCD_Write_char        ; write to screen
                SUB     R2, R2, #1
                CMP     R2, #0
                BGT     print_loop            ; loop 5 times
                LDMFD   SP!, {PC, R0, R1, R2}

; Divide1000 procedure
; R0 = number to divide
; returns the divided value in R0
divisor1000     DEFW    &418938               ; ~2^32/1000
Divide1000      STMFD   SP!, {LR, R1, R2}
                ADR     R1, divisor1000
                LDR     R1, [R1]
                UMULL   R2, R0, R0, R1        ; we're essentially doing n * 2^32/1000 then dividing by 2^32
                LDMFD   SP!, {PC, R1, R2}
