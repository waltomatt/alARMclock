;---------------------------------------------------------------------------
;       EX7: Key Deouncing and Keyboard Scanning
;       Matt Walton
;       Version 1.0
;       18th March 2019
;
;       This program implements a simple adding machine
;       Press * to Add!
;---------------------------------------------------------------------------

INCLUDE         includes/lcd.s

star_key        EQU       &2a

total_number    DEFW      0
input_number    DEFW      0

Main            BL        LCD_Clear         ; clear lcd
loop            SVC       4                 ; get last key pressed
                CMP       R0, #0            ; see if 0
                BEQ       loop
new_num         CMP       R0, #star_key
                BEQ       display_total
                BL        LCD_Write_char    ; write character
                SUB       R0, R0, #&30      ; ascii -> decimal
                ADR       R3, input_number  ; get the input number
                MOV       R1, #10           ; wanna x10
                LDR       R2, [R3]
                MUL       R1, R1, R2
                ADD       R1, R1, R0
                STR       R1, [R3]          ; store back
                BAL       loop


display_total   ADR       R1, input_number
                LDR       R0, [R1]
                MOV       R2, #0            ; set input number=0
                STR       R2, [R1]
                ADR       R1, total_number  ; load total
                LDR       R2, [R1]
                ADD       R0, R0, R2        ; total = total + input
                STR       R0, [R1]          ; store total back
                BL        LCD_Clear
                BL        Print             ; print total
total_loop      SVC       4
                CMP       R0, #0
                BEQ       total_loop
                BL        LCD_Clear
                B         new_num

; My print procedure from Ex5
; R0 = number to print
; Pushes 8 values to stack which are the ascii digits
Print           STMFD   SP!, {LR, R0, R1, R2}
                BL      LCD_Clear             ; clear the screen
                MOV     R2, #8
print_bcd_loop  SUB     R2, R2, #1
                BL      Divide10
                ADD     R1, R1, #&30          ; add 30 for ascii
                PUSH    {R1}                  ; push to stack
                CMP     R2, #0
                BGT     print_bcd_loop        ; loop 8 times for each digit
                MOV     R2, #8
print_loop      POP     {R0}                  ; pop into R0
                BL      LCD_Write_char        ; write to screen
                SUB     R2, R2, #1
                CMP     R2, #0
                BGT     print_loop            ; loop 8 times
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

; Divide10 procedure
; R0 = number to divide
; returns the divided value in R0, remainder in R1
divisor10       DEFW    &1999999A             ; ~2^32/10
Divide10        STMFD   SP!, {LR, R2, R3}
                ADR     R1, divisor10
                LDR     R1, [R1]
                UMULL   R2, R3, R0, R1        ; we're essentially doing n * 2^32/1000 then dividing by 2^32
                MOV     R1, #10
                MUL     R1, R3, R1            ; mul back by 10
                SUB     R1, R0, R1            ; remainder into r1
                MOV     R0, R3                ; move divided value to R0
                LDMFD   SP!, {PC, R2, R3}
