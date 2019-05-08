;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; menu.s
; This contains the code for the menu

                ALIGN    4

menu_state      DEFW    -1                        ; -1 if menu is closed, else is the index of the selected item
menu_set        DEFW    0                         ; if the menu is in time setting mode, 1 = hours, 2 = seconds

menu_set_hours  DEFW    0
menu_set_mins   DEFW    0

menu_cursor     DEFB    '> \0'
menu_arrow      EQU     0x5E

menu_max        EQU     4
menu_labels     DEFB    'Back to clock \0'
                DEFB    'Set alarm     \0'
                DEFB    'Clear alarm   \0'
                DEFB    'Set time      \0'
                DEFB    'Toggle Seconds\0'

                ALIGN   4

menu_functions  DEFW    Menu_close
                DEFW    Menu_setter
                DEFW    Alarm_clear
                DEFW    Menu_setter
                DEFW    Clock_tseconds


; Called to open the menu & hide the clock
Menu_open       STMFD   SP!, {LR, R0-R1}
                ADR     R0, menu_state
                MOV     R1, #0                    ; set menu state to 0 (open & first option)
                STR     R1, [R0]
                ADR     R0, clock_show            ; hide the clock for now
                STR     R1, [R0]
                BL      Menu_render
                LDMFD   SP!, {PC, R0-R1}

; Called to close the menu & show the clock again
Menu_close      STMFD   SP!, {LR, R0-R1}
                ADR     R0, menu_state
                MOV     R1, #-1                   ; set menu state to -1 (closed)
                STR     R1, [R0]
                ADR     R0, clock_show            ; show the clock again
                MOV     R1, #1
                STR     R1, [R0]
                BL      Clock_display
                LDMFD   SP!, {PC, R0-R1}
; Menu render function
Menu_render     STMFD   SP!, {LR, R0-R2}
                BL      LCD_Clear                 ; clear the screen
                ADR     R1, menu_state            ; load the menu state
                LDR     R1, [R1]
                ADR     R2, menu_set              ; are we setting a time?
                LDR     R2, [R2]
                CMP     R2, #0
                BEQ     mr_menu                   ; no, contiue rendering as normal
                BL      Menu_render_set           ; yes, render the setting menu
                B       mr_done
mr_menu         ADR     R0, menu_cursor           ; render the cursor
                BL      LCD_Write_str
                ADR     R0, menu_labels           ; render the first label
                MOV     R2, #15                   ; multiplying the state by 14 to get our label address
                MUL     R2, R2, R1
                ADD     R0, R0, R2                ; we now have the address in R0
                BL      LCD_Write_str             ; write to screen
                CMP     R1, #menu_max             ; check if we have one below
                BGE     mr_done
                ADD     R0, R0, #15               ; add 15 to current addr to get next label
                MOV     R1, R0                    ; move to R1 for now
                MOV     R0, #26                   ; we need 26 spaces to get to the next row & aligned
                BL      LCD_Do_spaces
                MOV     R0, R1
                BL      LCD_Write_str
mr_done         LDMFD   SP!, {PC, R0-R2}


; Render function for a submenu which allows the user to select a specific time
Menu_render_set STMFD   SP!, {LR, R0-R2}
                ADR     R1, menu_set_mins         ; load the mins and hours in
                LDR     R1, [R1]
                ADR     R2, menu_set_hours
                LDR     R2, [R2]
                BL      Clock_draw                ; draw a clock
                MOV     R0, #35                   ; 35 more characters till next line
                ADR     R1, menu_set              ; see which part of the time to draw arrows under
                LDR     R1, [R1]
                CMP     R1, #2                    ; if 2, then need to add 3 more spaces on to get arrows in right place
                ADDEQ   R0, R0, #3
                BL      LCD_Do_spaces
                MOV     R0, #menu_arrow           ; load our arrow character
                BL      LCD_Write_char            ; print char twice
                BL      LCD_Write_char
                LDMFD   SP!, {PC, R0-R2}


; checks if the menu button is pressed
Menu_press      STMFD   SP!, {LR, R0-R1}
                ADR     R0, menu_state            ; check if the menu is opened
                LDR     R0, [R0]
                CMP     R0, #0
                BGE     mo_check_set              ; if its open then see what we need to do
                BL      Menu_open                 ; open the menu
                B       mo_done                   ; We're done here
mo_check_set    ADR     R0, menu_set              ; check if we're setting a time
                LDR     R0, [R0]
                CMP     R0, #0
                BEQ     mo_function               ; if not then do the menu function
                BL      Menu_doset                ; do the setting of the time
                B       mo_done
mo_function     ADR     R0, menu_state            ; get the menu state (will be what the cursor is on)
                LDR     R0, [R0]
                MOV     R1, #4                    ; Need to multiply R0 by 4 to get the address of the function
                MUL     R0, R0, R1
                ADR     R1, menu_functions
                ADD     R1, R1, R0                ; add the offset for the menu function
                LDR     R1, [R1]                  ; load the menu function address
                MOV     LR, PC                    ; set LR
                MOV     PC, R1                    ; branch to our menu function
mo_done         LDMFD   SP!, {PC, R0-R1}

; Called when up button pressed
Menu_up         STMFD   SP!, {LR, R0-R1}
                ADR     R0, menu_set
                LDR     R0, [R0]
                CMP     R0, #1
                BLT     menu_scrl_u               ; if in menu, scroll up
                ADREQ   R0, menu_set_hours        ; set the hours if equal to 1
                ADRNE   R0, menu_set_mins         ; else set mins
                LDR     R1, [R0]
                ADD     R1, R1, #1                ; add 1 to it
                STR     R1, [R0]                  ; store back
                BL      Menu_render
                BAL     menu_up_dne
menu_scrl_u     ADR     R0, menu_state
                LDR     R1, [R0]
                CMP     R1, #-1
                BEQ     menu_up_dne               ; do nothing whilst menu is closed
                CMP     R1, #0                    ; check if 0, don't do anything if it is
                BEQ     menu_up_dne
                SUB     R1, R1, #1                ; else sub 1 and move up list
                STR     R1, [R0]
                BL      Menu_render               ; re-render menu
menu_up_dne     LDMFD   SP!, {PC, R0-R1}

; Called when down button pressed
Menu_down       STMFD   SP!, {LR, R0-R1}
                ADR     R0, menu_set
                LDR     R0, [R0]
                CMP     R0, #1
                BLT     menu_scrl_d               ; if in menu, scroll down
                ADREQ   R0, menu_set_hours        ; set the hours if equal to 1
                ADRNE   R0, menu_set_mins         ; else set mins
                LDR     R1, [R0]
                SUB     R1, R1, #1                ; sub 1 to it
                STR     R1, [R0]                  ; store back
menu_scrl_d     ADR     R0, menu_state
                LDR     R1, [R0]
                CMP     R1, #-1
                BEQ     menu_d_dne                ; do nothing whilst menu is closed
                CMP     R1, #menu_max             ; check if max, don't do anything if it is
                BEQ     menu_d_dne
                ADD     R1, R1, #1                ; else add 1 and move down list
                STR     R1, [R0]
                BL      Menu_render               ; re-render menu
menu_d_dne      LDMFD   SP!, {PC, R0-R1}



; Called when the user selects that they want to set an alarm in the menu
Menu_setter     STMFD   SP!, {LR, R0-R1}
                ADR     R0, menu_set
                MOV     R1, #1
                STR     R1, [R0]
                BL      Clock_get                 ; get the current time and set the window to that
                ADR     R0, menu_set_mins
                STR     R1, [R0]
                ADR     R0, menu_set_hours
                STR     R2, [R0]
                BL      Menu_render
                LDMFD   SP!, {PC, R0-R1}

; Called when the action button is pressed whilst setting the time
; It should move to mins if on hours, and save if on mins
Menu_doset      STMFD   SP!, {LR, R0-R2}
                ADR     R0, menu_set            ; check what state of setting we're on
                LDR     R1, [R0]
                CMP     R1, #1
                BNE     mds_set
                MOV     R1, #2                  ; move onto minutes
                STR     R1, [R0]
                BL      Menu_render
                B       mds_done
mds_set         MOV     R1, #0                  ; set menu_set back to 0
                STR     R1, [R0]
                ADR     R0, menu_set_hours      ; need to convert hours & minutes into seconds
                LDR     R0, [R0]
                MOV     R1, #secs_in_hour
                MUL     R0, R0, R1
                ADR     R1, menu_set_mins
                LDR     R1, [R1]
                MOV     R2, #secs_in_min
                MUL     R1, R1, R2
                ADD     R0, R0, R1              ; time in seconds is now in R0
                ADR     R1, menu_state          ; check if we're setting the clock or alarm
                LDR     R1, [R1]
                CMP     R1, #1                  ; 1 = set alarm, other would be set clock
                BLEQ    Alarm_set
                BLNE    Clock_set
                BL      Menu_close              ; close the menu
mds_done        LDMFD   SP!, {PC, R0-R2}

; Called when a key is pressed on the keypad
; input R0=value of key pressed

menu_key_pos    DEFW    0                       ; where we should put the entered value

Menu_key        STMFD   SP!, {LR, R0}
                ADR     R1, menu_set            ; see if we need to acknowledge input
                LDR     R1, [R1]
                CMP     R1, #0
                BEQ     mk_done
                ADR     R3, menu_key_pos        ; see if we've reached the end of the input
                LDR     R4, [R3]
                CMP     R4, #4
                BEQ     mk_done
                CMP     R4, #2
                ADRLT   R2, menu_set_hours      ; decide between setting hours & mins
                ADRGE   R2, menu_set_mins
                CMP     R4, #0
                BEQ     mk_10x
                CMP     R4, #2
                BEQ     mk_10x
                LDR     R1, [R2]
                ADD     R1, R1, R0
                B       mk_set
mk_10x          MOV     R1, #10                 ; multiply by 10
                MUL     R1, R1, R0
mk_set          STR     R1, [R2]
                ADD     R4, R4, #1              ; add one to menu_key_pos
                CMP     R4, #2                  ; check if moved onto next number
                STR     R4, [R3]
                BNE     mk_render
                ADR     R1, menu_set
                MOV     R0, #2                  ; set the display arrow to minutes
                STR     R0, [R1] 
mk_render       BL      Menu_render
mk_done         LDMFD   SP!, {PC, R0}
