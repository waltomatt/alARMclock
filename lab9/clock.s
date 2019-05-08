;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; clock.s
; This contains the code for keeping track & displaying of the current time

clock_time      DEFW    0                         ; current time since midnight in seconds

clock_show      DEFW    1                         ; whether to display the time or not (disabled when menu open etc)
clock_secs      DEFW    1                         ; whether to display seconds on the clock

secs_in_min     EQU     60
secs_in_hour    EQU     3600
secs_in_day     DEFW    86400

colon_code      EQU     0x3A                      ; ascii code for :


; Called by the timer interrupt every second
; Returns current time in seconds in R0
Clock_update    STMFD   SP!, {LR, R1}
                ADR     R1, clock_time            ; update clock time
                LDR     R0, [R1]
                ADD     R0, R0, #1
                STR     R0, [R1]
                BL      Clock_check               ; call function to check next day / alarms
                BL      Clock_display
                LDMFD   SP!, {PC, R1}

; Called to enable/disable clock
; inputs R0 = 0/1 (off/on)
Clock_sshow     STMFD   SP!, {LR, R0-R1}
                ADR     R1, clock_show
                STR     R0, [R1]
                LDMFD   SP!, {PC, R0-R1}

; Called when setting the time of the clock
; inputs: R0 = time since midnight in seconds

Clock_set       STMFD   SP!, {LR, R1}
                ADR     R1, clock_time
                STR     R0, [R1]
                BL      Clock_check
                LDMFD   SP!, {PC, R1}


; Checks if we need to roll over to a new day & call alarm checks
Clock_check     STMFD   SP!, {LR, R0-R2}
                ADR     R1, clock_time
                LDR     R0, [R1]
                ADR     R2, secs_in_day
                LDR     R2, [R2]
                CMP     R0, R2
                MOVGE   R0, #0                    ; reset clock to 0 if >= secs_in_day
                STRGE   R0, [R1]
                LDMFD   SP!, {PC, R0-R2}


; Called to toggle between showing seconds and not
Clock_tseconds  STMFD   SP!, {LR, R0-R1}
                ADR     R0, clock_secs
                LDR     R1, [R0]
                CMP     R1, #0                    ; check which mode we're in & set accordingly
                MOVEQ   R1, #1
                MOVNE   R1, #0
                STR     R1, [R0]
                LDMFD   SP!, {LR, R0-R1}


; Gets the current time in seconds, minutes, hours
; outputs: R0 = seconds , R1 = minutes, R2 = hours
Clock_get       STMFD   SP!, {LR}
                ADR     R0, clock_time
                LDR     R0, [R0]
                BL      Clock_format
                LDMFD   SP!, {PC}

; Converts seconds since midnight into hours, minutes, seconds
; inputs: R0 = time since midnight in seconds
; outputs: R0 = seconds , R1 = minutes, R2 = hours

Clock_format    MOV     R1, #0                    ; zero hours, mins
                MOV     R2, #0
cf_s_hours      CMP     R0, #secs_in_hour
                BLT     cf_s_mins                 ; no more hours left
                ADD     R2, R2, #1
                SUB     R0, R0, #secs_in_hour
                B       cf_s_hours
cf_s_mins       CMP     R0, #secs_in_min          ; check mins
                BLT     cf_done
                ADD     R1, R1, #1
                SUB     R0, R0, #secs_in_min
                B       cf_s_mins
cf_done         MOV     PC, LR                    ; we're done and left with seconds in R0


; Displays the current time on the LCD screen
Clock_display   STMFD   SP!, {LR, R0-R3}
                ADR     R0, clock_show            ; check if we should display the time
                LDR     R0, [R0]
                CMP     R0, #0
                BEQ     cd_done
                BL      LCD_Clear                 ; clear the screen
                BL      Clock_get                 ; get the time
                BL      Clock_draw                ; draw hours & mins
                MOV     R1, #35                   ; how many spaces we need to get to next line
                MOV     R3, R0                    ; move secs into r3 for now
                ADR     R0, clock_secs            ; check if we should display seconds
                LDR     R0, [R0]
                CMP     R0, #0
                BEQ     cd_alarm                  ; skip over the seconds
                MOV     R0, #colon_code
                BL      LCD_Write_char
                MOV     R0, R3                    ; move seconds back & print
                BL      LCD_Write_num
                SUB     R1, R1, #3                ; need 3 less spaces
cd_alarm        MOV     R0, R1
                BL      LCD_Do_spaces
                BL      Alarm_display             ; display alarm
cd_done         LDMFD   SP!, {PC, R0-R3}

; Function to draw a specific time (mins + hours)
; input: R1 = mins, R2 = hours

Clock_draw      STMFD   SP!, {LR, R0-R2}
                MOV     R0, R2                    ; move hours into R0 to print
                BL      LCD_Write_num
                MOV     R0, #colon_code           ; print a colon
                BL      LCD_Write_char
                MOV     R0, R1                    ; move mins into r0 & print
                BL      LCD_Write_num
                LDMFD   SP!, {PC, R0-R2}
