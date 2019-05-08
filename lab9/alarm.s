;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; alarm.s
; This code contains all the functions for setting/displaying/resetting alarms
; The alarm time is stored in seconds in alarm_time

alarm_str       DEFB    'Alarm: \0'
alarm_tstr      DEFB    'WAKE UP!!\0'
                ALIGN   4
alarm_time      DEFW    -1                        ; alarm time, -1 for disabled
alarm_active    DEFW    0                         ; is the alarm going off?

Alarm_clear     STMFD   SP!, {LR, R0}
                MOV     R0, #-1
                BL      Alarm_set
                LDMFD   SP!, {PC, R0}

; Called to set an alarm, R0 is time in seconds
Alarm_set       STMFD   SP!, {LR, R0-R1}
                ADR     R1, alarm_time
                STR     R0, [R1]
                LDMFD   SP!, {PC, R0-R1}

; Called to print the current set alarm time underneath the time

Alarm_display   STMFD   SP!, {LR, R0-R1}
                ADR     R1, alarm_time
                LDR     R1, [R1]                  ; load alarm time
                CMP     R1, #-1                   ; Check if no alarm set
                BEQ     ad_done                   ; don't draw alarm
                ADR     R0, alarm_str
                BL      LCD_Write_str             ; print alarm prefix
                MOV     R0, R1
                BL      Clock_format              ; format the alarm
                BL      Clock_draw                ; draw it
ad_done         LDMFD   SP!, {PC, R0-R1}

; Called to stop the alarm whilst it is going off

Alarm_reset     STMFD   SP!, {LR, R1}
                ADR     R0, alarm_active          ; check alarm active
                LDR     R1, [R0]
                CMP     R1, #1
                MOVNE   R0, #0
                BNE     ar_dne                    ; not active, finished
                MOV     R1, #0
                STR     R1, [R0]                  ; disable alarm
                MOV     R0, #0
                SVC     3                         ; Disable buzzer
                ADR     R0, alarm_active          ; set alarm inactive
                MOV     R1, #0
                STR     R1, [R0]
                MOV     R0, #1
                BL      Clock_sshow               ; set clock to show again
                MOV     R0, #1                    ; block any other button actions
ar_dne          LDMFD   SP!, {PC, R1}

; check the alarm is going off
; R0 = current time in seconds

Alarm_check     STMFD   SP!, {LR, R0-R1}
                ADR     R1, alarm_time
                LDR     R1, [R1]                  ; load alarm time
                CMP     R0, R1
                BNE     ac_done                   ; alarm not going off
                BL      Alarm_trigger             ; set alarm off
ac_done         LDMFD   SP!, {PC, R0-R1}

; Called when the current time is equal to the alarm time
; Enables buzzer, prints the message and hides the clock

Alarm_trigger   STMFD   SP!, {LR, R0-R1}
                BL      LCD_Clear                 ; clear screen
                ADR     R0, alarm_tstr            ; print alarm message
                BL      LCD_Write_str
                MOV     R0, #1                    ; Enable buzzer
                SVC     3
                ADR     R0, alarm_active          ; set alarm active
                MOV     R1, #1
                STR     R1, [R0]
                MOV     R0, #0
                BL      Clock_sshow               ; set clock to not show
                LDMFD   SP!, {PC, R0-R1}
