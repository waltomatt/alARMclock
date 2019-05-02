;---------------------------------------------------------------------------
;       Matt Walton
;       Version 1.3
;       18th March 2019
;---------------------------------------------------------------------------

; os.s
; This contains the basic 'operating system' code
; It initalises the devices, defines service routines,
; and also contains the device driver for the HD44780 LCD controller

              ORG   &0
              B     Init_stacks       ; define what to do on reset
              ORG   &8
              B     SVC_entry         ; define what to do on svc
              ORG   &18
              B     ISR_entry
              B     FIQ_entry

stack_size    EQU   &20               ; Define the stack size for all user modes

super_stack   DEFS  stack_size
user_stack    DEFS  stack_size
fiq_stack     DEFS  stack_size
irq_stack     DEFS  stack_size
svc_stack     DEFS  stack_size

cpsr_sys      EQU   &1F
cpsr_svc      EQU   &13
cpsr_usr      EQU   &10
cpsr_fiq      EQU   &11
cpsr_irq      EQU   &12

irq_mask      EQU   &40
fiq_mask      EQU   &80

port_A        EQU   &10000000         ; statically define the base for the data port of the LCD
port_B_off    EQU   &00000004         ; define the adr of port B as an offset to port A

bit_7         EQU   &80
bit_6         EQU   &40
bit_5         EQU   &20
bit_4         EQU   &10
bit_3         EQU   &8
bit_2         EQU   &4
bit_1         EQU   &2
bit_0         EQU   &1


base_adr      EQU   &10000000         ; base address for i/o
piob_ofs      EQU   &4                ; address of PIOB
ire_ofs       EQU   &1c               ; offset for interupt enable
ira_ofs       EQU   &18               ; offset for interrupt active


ir_enabled    DEFW  0b00000001        ; which interrupts to enable, for now just the timer is enabled

ir_ubutton    EQU   bit_6
ir_lbutton    EQU   bit_7
ir_timer      EQU   bit_0

svc_jmax      EQU   5
svc_jumps     DEFW  LCD_write         ; SVC 0 = LCD_write
              DEFW  Timer_reset       ; SVC 1 = Timer_reset
              DEFW  Timer_read        ; SVC 2 = Timer_read
              DEFW  Get_PIOB          ; SVC 3 = Get_PIOB
              DEFW  Get_last_key      ; SVC 4 = Get_last_key

              ALIGN 4

INCLUDE       program.s                 ; include our program code


; OS procedure to initialise the supervisor and user stacks
Init_stacks   ADR   SP, super_stack + stack_size    ; set stack pointer for supervisor
              MRS   R0, CPSR                        ; load cpsr into r0
              BIC   R0, R0, #&1F                    ; clear mode field
              ORR   R0, R0, #cpsr_sys               ; set mode to system
              MSR   CPSR, R0                        ; write back to CPSR
              ADR   SP, user_stack + stack_size     ; set SP for user

              MRS   R0, CPSR                        ; load cpsr into r0
              BIC   R0, R0, #&1F                    ; clear mode field
              ORR   R0, R0, #cpsr_fiq               ; set mode to FIQ
              MSR   CPSR, R0                        ; write back to CPSR
              ADR   SP, fiq_stack + stack_size      ; set SP

              MRS   R0, CPSR                        ; load cpsr into r0
              BIC   R0, R0, #&1F                    ; clear mode field
              ORR   R0, R0, #cpsr_irq               ; set mode to IRQ
              MSR   CPSR, R0                        ; write back to CPSR
              ADR   SP, irq_stack + stack_size      ; set SP

              MRS   R0, CPSR                        ; load cpsr into r0
              BIC   R0, R0, #&1F                    ; clear mode field
              ORR   R0, R0, #cpsr_svc               ; set mode to SVC
              MSR   CPSR, R0                        ; write back to CPSR
              ADR   SP, svc_stack + stack_size      ; set SP

; OS procedure to enable FIQ AND IRQ interrupts
En_interrupts MRS   R0, CPSR                        ; enable on CPU
              BIC   R0, R0, #irq_mask               ; enable IRQ
              BIC   R0, R0, #fiq_mask               ; enable FIQ
              MSR   CPSR, R0                        ; write back to CPSR
              ADR   R0, ir_enabled                  ; load our enabled flags
              LDR   R0, [R0]
              MOV   R1, #base_adr                   ; load the interrupt enable address
              ADD   R1, R1, #ire_ofs
              STR   R0, [R1]                        ; do our interrupt enables


; OS procedure to initalise the LCD
Init_lcd      MOV   R1, #cmd_clear
              MOV   R0, #0
              SVC   0

Init_program  MRS   R0, CPSR
              BIC   R0, R0, #&1F
              ORR   R0, R0, #cpsr_usr               ; set mode to user
              MSR   CPSR, R0                        ; write back to CPSR
              B     Main                            ; branch to program main

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

; Interrupt service routine entry point
ISR_entry     SUB   LR, LR, #4                       ; correct the return address
              STMFD SP!, {R0-R2, LR}                 ; Store working regs & return adr
              MOV   R1, #base_adr                    ; check which interrupt fired
              ADD   R1, R1, #ira_ofs
              LDRB  R0, [R1]
              TST   R0, #ir_timer
              BEQ   isr_done                         ; not timer / no interrupt that we care about has fired
              BIC   R0, R0, #ir_timer                ; clear the bit
              STRB  R0, [R1]                         ; store back, to aknowledge interrupt acceptance
              BL    Scan_keyboard                    ; scan the keyboard
              BL    Timer_update                     ; do timer update

isr_done      LDMFD SP!, {R0-R2, PC}^                ; restore & return

FIQ_entry     SUB   LR, LR, #4                       ; correct the return address
              STMFD SP!, {R0-R2, LR}                 ; Store working regs & return adr

              LDMFD SP!, {R0-R2, PC}^                ; restore & return


; button SVC routine
Get_PIOB      MOV     R0, #(base_adr + piob_ofs)
              LDRB    R0, [R0]
              B       svc_done


; include drivers
INCLUDE       drivers/keyboard.s
INCLUDE       drivers/lcd.s
INCLUDE       drivers/timer.s
