;--------------------------------------------------------
;     Matt Walton
;     Version 1.0
;     29th April 2019
;
;     EX9 - Final Project (Alarm Clock)
;--------------------------------------------------------

; constants.s
; Defines all constants for the operating system

bit_7           EQU     &80
bit_6           EQU     &40
bit_5           EQU     &20
bit_4           EQU     &10
bit_3           EQU     &8
bit_2           EQU     &4
bit_1           EQU     &2
bit_0           EQU     &1

stack_size      EQU     0x30                ; define the stack size for all user modes

cpsr_usr        EQU     0x10                ; define the CPSR codes for each mode
cpsr_fiq        EQU     0x11
cpsr_irq        EQU     0x12
cpsr_svc        EQU     0x13
cpsr_abt        EQU     0x17
cpsr_und        EQU     0x1B
cpsr_sys        EQU     0x1F

base_adr        EQU     0x10000000          ; base address for i/o
piob_ofs        EQU     0x4                 ; offset for port b
timer_ofs       EQU     0x8
ire_ofs         EQU     &1c                 ; offset for interupt enable
ira_ofs         EQU     &18                 ; offset for interrupt active

irq_mask        EQU     &80

ir_timer        EQU     bit_0
ir_ubutton      EQU     bit_6
ir_lbutton      EQU     bit_7
