.include "constants.inc"

.segment "CODE"
.import main

; Initialize APU
.proc init_APU
    ldy #$13
@loop:  
    lda APU_regs,y
    sta $4000,y
    dey
    bpl @loop

    lda #$0f
    sta $4015
    lda #$40
    sta $4017
  rts
.endproc

.export clear_OAM
.proc clear_OAM
    lda #$F6
    ldx #$00
    @clroam:
        sta $0200,X
        inx
        inx
        inx
        inx
        bne @clroam

    rts
.endproc

.export clear_PPU
.proc clear_PPU
    lda PPUSTATUS
    lda #$00
    tax  ; High bit address
    tay  ; Low bit address
    @loop_high:
        @loop_low:
            stx PPUADDR
            sty PPUADDR
            sta PPUDATA
            iny
            bne @loop_low
    
        inx
        cpx #$40
        bne @loop_high

    rts
.endproc

.export irq_handler
.proc irq_handler
    rti
.endproc

.export nmi_handler
; Copy 256 bytes from $0200 to $02ff
.proc nmi_handler
    LDA #$00
    STA OAMADDR
    LDA #$02
    STA OAMDMA
    LDA #$00
    STA PPUSCROLL
    STA PPUSCROLL
    RTI
.endproc

.export reset_handler
.proc reset_handler
    sei        ; ignore IRQs
    cld        ; disable decimal mode
    ldx #$40
    stx $4017  ; disable APU frame IRQ
    ldx #$ff
    txs        ; Set up stack
    inx        ; now X = 0
    stx PPUCTRL  ; disable NMI
    stx PPUMASK  ; disable rendering
    stx $4010  ; disable DMC IRQs

    bit PPUSTATUS
    @vblankwait1:  
        bit PPUSTATUS
        bpl @vblankwait1

    txa
    @clrmem:
        sta $000,x
        sta $100,x
        sta $300,x
        sta $400,x
        sta $500,x
        sta $600,x
        sta $700,x
        inx
        bne @clrmem

    jsr init_APU
    jsr clear_OAM
    jsr clear_PPU
    
    @vblankwait2:
        bit   PPUSTATUS
        bpl @vblankwait2

    jmp main
.endproc

.segment "RODATA"
APU_regs:
    .byte $30, $08, $00, $00
    .byte $30, $08, $00, $00
    .byte $80, $00, $00, $00
    .byte $30, $00, $00, $00
    .byte $00, $00, $00, $00