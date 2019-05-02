;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; os.s
; This contains the 'operating system code'
; Initialises devices, defines service & interrupt routines

                ORG     0x0
                B       OS_init                           ; defines what to do on reset
                ORG     0x8
                B       OS_svc                            ; defines what to do on svc
                ORG     0x18
                B       OS_irq                            ; irq handler

                ORG     0x20

                INCLUDE constants.s                       ; include our constants

usr_stack       DEFS    stack_size                        ; define the space for all the stacks
irq_stack       DEFS    stack_size
svc_stack       DEFS    stack_size

ir_enabled      DEFW    ir_ubutton OR ir_lbutton OR ir_timer

svc_jmax        EQU     2
svc_jumps       DEFW    LCD_write                         ; SVC 0 = LCD_write
                DEFW    LCD_set_light                     ; SVC 1 = LCD_set_light

; OS_init - initalises the stacks, interrupts, drivers, etc

OS_init
                MRS      R0, CPSR                         ; load CPSR into r0
                BIC      R0, R0, #cpsr_sys                ; clear usermode
                ORR      R0, R0, #cpsr_sys                ; set user to system
                MSR      CPSR, R0                         ; write back cpsr
                ADR      SP, usr_stack + stack_size       ; setup usr stack

                BIC      R0, R0, #cpsr_sys                ; do the same for IRQ
                ORR      R0, R0, #cpsr_irq
                MSR      CPSR, R0
                ADR      SP, irq_stack + stack_size

                BIC      R0, R0, #cpsr_sys                ; and for svc
                ORR      R0, R0, #cpsr_svc
                MSR      CPSR, R0
                ADR      SP, svc_stack + stack_size

                BIC      R0, R0, #cpsr_sys                ; switch back to svc
                ORR      R0, R0, #cpsr_svc
                MSR      CPSR, R0

; OS procedure to enable IRQ interrupts

OS_en_irq       ADR     R0, ir_enabled                    ; load enabled flags
                LDR     R0, [R0]
                MOV     R1, #base_adr
                ADD     R1, R1, #ire_ofs
                STR     R0, [R1]                          ; enable our interrupts
                MRS     R0, CPSR
                BIC     R0, R0, #irq_mask                 ; enable IRQ on CPU
                MSR     CPSR, R0

OS_init_lcd     MOV     R1, #lcd_cmd_clr                  ; clear our lcd screen
                MOV     R0, #0                            ; 0 = command
                SVC     0

OS_program      MRS     R0, CPSR
                BIC     R0, R0, #cpsr_sys
                ORR     R0, R0, #cpsr_usr                 ; set mode to user
                MSR     CPSR,  R0
                B       Main                              ; branch to main program

; SVC entry point

OS_svc          STMFD   SP!, {LR}
                LDR     R14, [LR, #-4]                    ; copy the calling inst (ret adr - 4) to R1
                BIC     R14, R14, #&FF000000              ; mask off opcode
                CMP     R14, #svc_jmax                    ; validation of svc code
                BPL     svc_done                          ; svc code > max
                CMP     R14, #0                           ; svc code < 0
                BMI     svc_done
                STMFD   SP!, {R0}                         ; push r0
                ADR     R0, svc_jumps                     ; get adr of jump table
                ADD     R14, R0, R14 LSL #2               ; add R0 * 4
                LDMFD   SP!, {R0}                         ; pop r0
                LDR     PC, [R14]

; procedure to be called at the end of a service routine, returns us back
svc_done        LDMFD   SP!, {LR}
                MOVS    PC, LR

; Interrupt service routine

OS_irq          SUB     LR, LR, #4
                STMFD   SP!, {R0-R2, LR}                 ; Store working regs & return adr
                MOV     R1, #base_adr                    ; check which interrupt fired
                ADD     R1, R1, #ira_ofs
                LDRB    R0, [R1]
                TST     R0, #ir_ubutton                  ; check if upper button
                BICNE   R0, R0, #ir_ubutton              ; mark done
                BLNE    Ubutton_press                    ; run routine
                TST     R0, #ir_lbutton                  ; check lower button
                BICNE   R0, R0, #ir_lbutton
                BLNE    Lbutton_press
                TST     R0, #ir_timer                    ; check timer
                BICNE   R0, R0, #ir_timer
                BLNE    Clock_update
                STRB    R0, [R1]                         ; acknowledge interrupt
isr_done        LDMFD   SP!, {R0-R2, PC}^                ; restore & return

Ubutton_press   MOV     PC, LR
Lbutton_press   MOV     PC, LR

; include drivers
                INCLUDE drivers/lcd.s

; include components
                INCLUDE clock.s
                INCLUDE util.s

; include program
                INCLUDE program.s
