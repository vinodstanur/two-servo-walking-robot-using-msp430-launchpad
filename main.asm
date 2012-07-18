;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Project: Two servo two directional walking robot with ti launchpad
; author: vinod s <vinodstanur@gmail.com> 
; date: Tue Jun 12
; processor: msp430g2231
; assembler: naken430asm 
; development platform: linux
; servo connections: P1.1 & P1.2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.include "msp430g2x31.inc"
 
#define TOTAL_SERVO 2
 
#define TOP_OF_RAM 0x27f
 
#define CALIBC1_1MHZ 0x10ff
#define CALDCO_1MHZ 0x10fe   
 
#define SERVO_INDEX TOP_OF_RAM
#define SERVO_BUFFER TOP_OF_RAM-((TOTAL_SERVO+1)*4)-3
#define TOP_OF_STACK SERVO_BUFFER - 2
#define SERVO_START_ANGLE SERVO_BUFFER
#define SERVO_START_PINS SERVO_START_ANGLE+2
;;SERVO;;
#define SERVO1_ANGLE SERVO_BUFFER+4
#define SERVO1_PIN SERVO_BUFFER+6
#define SERVO2_ANGLE SERVO_BUFFER+8
#define SERVO2_PIN SERVO_BUFFER+10
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
org 0xf800             ;flash begins 
startup:                 ;startup code which sets the stack pointer and disable WDT
    mov.w #(WDTPW|WDTHOLD), &WDTCTL ;disabling watch dog timer, otherwise it will reset on regular interval
    mov.w #(TOP_OF_STACK), SP     ;SETTING TOP OF THE STACK ON STACK POINTER
    call #main           ; (not a must :-))
     
;;;MAIN PROGRAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:
    mov.b &CALIBC1_1MHZ, &BCSCTL1
    mov.b &CALDCO_1MHZ, &DCOCTL
    mov.b #0, &P1OUT
    mov.b #255,&P1DIR
    call #timer_init
    call #servo_init
    eint
  
    infinite_loop:
        mov.w #5,r14
        ntimes1:
            call #walk_forward
            dec r14
            jnz ntimes1
        mov.w #5,r14
        call #stop_idle
        call #delay
        ntimes2:
            call #walk_reverse
            dec r14
            jnz ntimes2
        call #stop_idle
        call #delay
        jmp infinite_loop
 
 
;-------------INTERRUPT-------------------------------------;
ISR: 
    xor.w r9, r9
    mov.b &(SERVO_INDEX), r9
    mov.w (SERVO_BUFFER)(r9), &TACCR0
    mov.b (SERVO_BUFFER+2)(r9), &P1OUT
    add.b #4,r9
    cmp.b #((TOTAL_SERVO+1)*4) , r9
    jnz exit
    clr.b r9
    exit:
    mov.b r9, &(SERVO_INDEX)
    reti
;------------------------------------------------------------;
 
;;;;;;;;;;;;;;;;;OTHER FUNCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
stop_idle:
    mov.w #1500, &(SERVO1_ANGLE)
    call #delay
    mov.w #1500, &(SERVO2_ANGLE)
    call #delay
    ret
     
walk_forward:
    mov.w #1000, &(SERVO1_ANGLE)
    call #delay
    mov.w #1000, &(SERVO2_ANGLE)
    call #delay
    mov.w #2000, &(SERVO1_ANGLE)
    call #delay
    mov.w #2000, &(SERVO2_ANGLE)
    call #delay
    ret
 
walk_reverse:
    mov.w #1000, &(SERVO2_ANGLE)
    call #delay
    mov.w #1000, &(SERVO1_ANGLE)
    call #delay
    mov.w #2000, &(SERVO2_ANGLE)
    call #delay
    mov.w #2000, &(SERVO1_ANGLE)
    call #delay
    ret
  
delay:
    push R10
    mov.w #0xffff,R10
    oo:
        dec R10
        jnz oo
    pop R10
    ret
     
timer_init:
    mov.w #20000, &TACCR0 
    mov.w #CCIE, &TACCTL0 
    mov.w #(TASSEL_2|ID_0|MC_1|TACLR), &TACTL
    ret
 
servo_init:
    mov.w #20000, &(SERVO_START_ANGLE)
    mov.w #1500, &(SERVO1_ANGLE)
    mov.w #1500, &(SERVO2_ANGLE)
    mov.b #0, &(SERVO_START_PINS)
    mov.b #2, &(SERVO1_PIN)
    mov.b #4, &(SERVO2_PIN)
    mov.b #0,&(SERVO_INDEX)
    ret
  
;VECTOS
org 0xfffe                  ;reset vecor
    dw startup             ;to write start address to 0xfffe on programming
org 0xfff2                  ;timer interrupt vecTOP_OF_RAM (CC)
    dw ISR  ;to write isr address to 0xfff2 on programming
