;---------------------------------------------------------------------------
;       Matt Walton
;       Version 1.1
;       26th February 2019
;---------------------------------------------------------------------------

; os.s
; This contains the basic 'operating system' code
; It initalises the devices, defines service routines,
; and also contains the device driver for the HD44780 LCD controller

              ORG   0
              B     Init_stacks       ; define what to do on reset
              ORG   8
              B     SVC_entry         ; define what to do on svc

stack_size    EQU   &80               ; Define the stack size for both user and supervisor

super_stack   DEFS  stack_size
user_stack    DEFS  stack_size

cpsr_sys      EQU   &1F
cpsr_svc      EQU   &13
cpsr_usr      EQU   &10

port_A        EQU   &10000000         ; statically define the base for the data port of the LCD
port_B_off    EQU   &00000004         ; define the adr of port B as an offset to port A

bit_7         EQU   &80
bit_2         EQU   &4
bit_1         EQU   &2
bit_0         EQU   &1

lcd_rw        EQU   bit_2
lcd_rs        EQU   bit_1
lcd_e         EQU   bit_0

cmd_clear     EQU   &1

timer_adr     EQU   &10000008         ; the address of the timer module
piob_adr      EQU   &10000004         ; address of PIOB

timer_ms      DEFW  0                 ; timer's count in ms
timer_last    DEFW  0                 ; last reading from timer

svc_jmax      EQU   4
svc_jumps     DEFW  LCD_write         ; SVC 0 = LCD_write
              DEFW  Timer_reset       ; SVC 1 = Timer_reset
              DEFW  Timer_read        ; SVC 2 = Timer_read
              DEFW  Get_PIOB          ; SVC 3 = Get_PIOB

INCLUDE       part2.s              ; include our program code


; OS procedure to initialise the supervisor and user stacks
Init_stacks   ADR   SP, super_stack + stack_size    ; set stack pointer for supervisor
              MRS   R0, CPSR                        ; load cpsr into r0
              BIC   R0, R0, #&1F                    ; clear mode field
              ORR   R0, R0, #cpsr_sys               ; set mode to system
              MSR   CPSR, R0                        ; write back to CPSR
              ADR   SP, user_stack + stack_size     ; set SP for user
              MRS   R0, CPSR                        ; load cpsr into r0
              BIC   R0, R0, #&1F                    ; clear mode field
              ORR   R0, R0, #cpsr_svc               ; set mode to supervisor
              MSR   CPSR, R0                        ; write back to CPSR


; OS procedure to initalise the LCD
Init_lcd      MOV   R1, #cmd_clear
              MOV   R0, #0
              SVC   0

Init_program  MRS   R0, CPSR
              BIC   R0, R0, #&1F
              ORR   R0, R0, #cpsr_usr               ; set mode to user
              MSR   CPSR, R0                        ; write back to CPSR
              B     Main                            ; branch to program main

;TODO: make this use r14 pls
SVC_entry     STMFD SP!, {LR}
              LDR   R14, [LR, #-4]                   ; copy the calling inst (ret adr - 4) to R1
              BIC   R14, R14, #&FF000000             ; mask off opcode
              CMP   R14, #svc_jmax                   ; validation of svc code
              BPL   svc_done                         ; svc code > max
              CMP   R14, #0                          ; svc code < 0
              BMI   svc_done
              STMFD SP!, {R0}                        ; push r0
              ADR   R0, svc_jumps                    ; get adr of jump table
              ADD   R14, R0, R14 LSL #2              ; add R0 * 4
              LDMFD SP!, {R0}                        ; pop r0
              LDR   PC, [R14]

svc_done      LDMFD SP!, {LR}
              MOVS  PC, LR

; LCD DRIVER:

; Procedure to check if the LCD is ready & wait until it is
Wait_ready    STMFD SP!, {LR, R0, R1, R2}
              MOV   R0, #port_A                 ; set R0 to adr of port A
              LDRB  R1, [R0, #port_B_off]       ; load contents of port B
              ORR   R1, R1, #lcd_rw             ; set r/w bit to 1
              BIC   R1, R1, #lcd_rs             ; set RS=0
              STRB  R1, [R0, #port_B_off]       ; write cmd to port B
wr_loop       ORR   R1, R1, #lcd_e              ; set E=1
              STRB  R1, [R0, #port_B_off]       ; write data to port B
              LDRB  R2, [R0]                    ; read our status bytes
              BIC   R1, R1, #lcd_e              ; set E=0
              STRB  R1, [R0, #port_B_off]       ; write command back
              AND   R2, R2, #bit_7
              SUBS  R2, R2, #bit_7
              BEQ   wr_loop               ; we are still busy, poll again
              LDMFD SP!, {PC, R0, R1, R2}       ; pop & return

; procedure to either write a cmd or data to the lcd
; R0 (1/0) specifies the value of RS (0 - cmd, 1- data)
; R1 specifies the cmd/character
LCD_write     STMFD SP!, {LR, R2, R3}
              BL    Wait_ready                  ; wait for lcd to be ready
              MOV   R2, #port_A                 ; load adr of port A into R2
              LDRB  R3, [R2, #port_B_off]       ; load ctrl byte to r3
              BIC   R3, R3, #lcd_rw             ; set RW=0 (we're writing)
              BIC   R3, R3, #lcd_rs             ; clear rs
              ORR   R3, R3, R0 lsl #1           ; set RS=R0
              STRB  R3, [R2, #port_B_off]       ; store back in port B
              STRB  R1, [R2]                    ; store our data
              ORR   R3, R3, #lcd_e              ; set E=1
              STRB  R3, [R2, #port_B_off]       ; store back
              BIC   R3, R3, #lcd_e              ; set E=0
              STRB  R3, [R2, #port_B_off]       ; store back
              LDMFD SP!, {LR, R2, R3}
              B     svc_done

; TIMER code

; procudure to poll the timer and returns the current elapsed ms since reset
; returns in R0
Timer_read    STMFD   SP!, {LR, R1, R2, R3}
              ADR     R0, timer_last            ; get adr of last clock reading
              LDR     R0, [R0]                  ; load
              MOV     R1, #timer_adr            ; get address of the clock
              LDR     R1, [R1]                  ; read clock
              SUBS    R0, R1, R0                ; find difference between last reading
              BPL     poll_pos                  ; if >= 0 then cont
              ADD     R0, R0, #256              ; if not, add 256
poll_pos      ADR     R2, timer_ms              ; update timer memory
              LDR     R3, [R2]
              ADD     R3, R0, R3
              STR     R3, [R2]
              ADR     R0, timer_last            ; update last reading
              STR     R1, [R0]
              MOV     R0, R3
              LDMFD   SP!, {LR, R1, R2, R3}     ; return
              B       svc_done

; procedure to reset the timer to 0
Timer_reset   STMFD   SP!, {LR, R0, R1}
              ADR     R0, timer_ms
              MOV     R1, #0
              STR     R1, [R0]
              MOV     R1, #timer_adr            ; get a timer reading to make sure we're accurate
              LDR     R1, [R1]
              ADR     R0, timer_last            ; update last reading
              STR     R1, [R0]
              LDMFD   SP!, {LR, R0, R1}
              B       svc_done


; button SVC routine
Get_PIOB      MOV     R0, #piob_adr
              LDRB    R0, [R0]
              B       svc_done
