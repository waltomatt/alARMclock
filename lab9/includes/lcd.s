;---------------------------------------------------------------------------
;       Matt Walton
;       Version 1.0
;       18th February 2019
;
;       This program implements my previous code for writing to an LCD
;       but instead making sure the driver is run in supervisor mode
;       and calls are made from user code to this via SVC calls.
;
;---------------------------------------------------------------------------

; lcd.s
; this provides functions to make calls to the LCD driver a bit nicer

lcd_code_clear  EQU   1

; Procedure to write a character to the LCD using the SVC call
; R0 = character
LCD_Write_char  STMFD   SP!, {LR, R1 ,R0}
                MOV     R1, R0                    ; move our value at R0 to R1
                MOV     R0, #1                    ; we want to write a character
                SVC     0                         ; Call our service routine
                LDMFD   SP!, {PC, R1, R0}


; Procedure to send a command to the LCD controller
; R0 = cmd
LCD_Write_cmd   STMFD   SP!, {LR, R1 ,R0}
                MOV     R1, R0                    ; move our value at R0 to R1
                MOV     R0, #0                    ; we want to send a command
                SVC     0                         ; Call our service routine
                LDMFD   SP!, {PC, R1, R0}

; Procedure to write a string to the LCD
; R0 = start address of string
; The procedure will continue until a null byte string terminator is hit

LCD_Write_str   STMFD   SP!, {LR, R0, R1}         ; we're using R2, and want to push the LR to the stack
                MOV     R1, R0                    ; move R0 > R1
next_byte       LDRB    R0, [R1], #1              ; load our byte into R2 and increment
                CMP     R0, #0                    ; are we at null byte? end of string?
                BEQ     wstr_dne
                BL      LCD_Write_char
                BAL     next_byte
wstr_dne        LDMFD   SP!, {PC, R0, R1}         ; pop our registers back and branch back

; Procedure to clear the screen of the LCD
LCD_Clear       STMFD   SP!, {LR, R0}
                MOV     R0, #lcd_code_clear
                BL      LCD_Write_cmd
                LDMFD   SP!, {PC, R0}


; Procedure to set the status of the LCD backlight
; R0 = 1 for on , 0 for off

LCD_Set_light   SVC     1                         ; just call the service routine
                MOV     PC, LR

; Procedure for writing a 2 digit 0-padded number to the LCD
; R0 = number
LCD_Write_num   STMFD   SP!, {LR, R0-R1}
                BL      Divide10                  ; now we can just print r0 then r1
                ADD     R0, R0, #&30              ; add 0x30 to them for ascii
                ADD     R1, R1, #&30
                BL      LCD_Write_char
                MOV     R0, R1
                BL      LCD_Write_char
                LDMFD   SP!, {PC, R0-R1}

; Procedure for writing x number of spaces (0x20) for padding
; R0 = number of spaces
LCD_Do_spaces   STMFD   SP!, {LR, R0-R1}
                MOV     R1, R0
                MOV     R0, #&20
lcdds_loop      BL      LCD_Write_char
                SUB     R1, R1, #1
                CMP     R1, #0
                BGT     lcdds_loop
                LDMFD   SP!, {PC, R0-R1}
