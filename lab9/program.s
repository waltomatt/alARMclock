;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; program.s

; Project features:
; - Working clock displayed on LCD screen with optional seconds toggle
; - Menu to set alarms / time / other options (access with button next to screen)
; - Mostly interrupt driven system
; - SVC calls to print to LCD, get PIOB status and activate buzzer
; - Simple buzzer
; - Keypad input for setting alarm/time


; Most of this application is interrupt driven so we only really have to do non O/S initalisation tasks here

Main      MOV   R0, #1
          BL    LCD_Set_light                     ; Enable LCD backlight

done      B     done
