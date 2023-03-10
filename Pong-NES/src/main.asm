.include "constants.inc"
.include "variables.inc"
.include "header.inc"

.segment "CODE"

.proc update_screen
    vblankwait:
        bit PPUSTATUS
        bpl vblankwait

    ldx #%10010000  ; Set NMI interrupt and set background pattern table address
    stx PPUCTRL
    ldx #%00011110  ; turn on screen
    stx PPUMASK

    rts
.endproc

.proc draw_border
    ldx PPUSTATUS
    ldx #$00  ; Store PPU address index from border_corners data
    ldy #$01  ; Store tile index from pattern table

    ; Draw the corners of the border
    corners:
        lda border_corners,X
        sta PPUADDR
        inx
        lda border_corners,X
        sta PPUADDR
        sty PPUDATA
        inx
        iny
        cpx #$08
        bcc corners

    ; Draw top part of border
    lda #$20  ; High bit address of tile in nametable
    ldx #$22  ; Low bit address of tile in nametable
    ldy #$05  ; Tile index from pattern table to be drawn
    top:
        sta PPUADDR
        stx PPUADDR
        sty PPUDATA
        inx
        cpx #$3E
        bmi top

    ; Draw bottom part of border
    lda #$23
    ldx #$82
    ldy #$06
    bottom:
        sta PPUADDR
        stx PPUADDR
        sty PPUDATA
        inx
        cpx #$9E
        bmi bottom

    ; Draw left side of border
    lda #$41  ; Low bit address of tile in nametable
    ldx #$20  ; High bit address of tile in nametable
    ldy #$07  ; Tile index from pattern table to be drawn
    clc
    left:
        stx PPUADDR
        sta PPUADDR
        sty PPUDATA
        adc #$20            ; Add denary 16 to low bit address to draw on the next line of nametable
        bcs inc_left        ; Check if the low bit address has passed $FF
            jmp cont_left
        inc_left:
            inx             ; Increment the high bit address
            clc
        cont_left:

        ; Check if the nametable address is equal to $2381 to exit loop
        cpx #$23
        beq exit_left
            jmp left
        exit_left:
            cmp #$81
            bne left

    ; Draw right side of border - replica of left side drawing
    lda #$5E
    ldx #$20
    ldy #$08
    clc
    right:
        stx PPUADDR
        sta PPUADDR
        sty PPUDATA
        adc #$20
        bcs inc_right
            jmp cont_right
        inc_right:
            inx
            clc
        cont_right:

        cpx #$23
        beq exit_right
            jmp right
        exit_right:
            cmp #$9E
            bne right

    rts
.endproc

.proc move_ball
    ; Change the Y position
    lda vel
    and #%00001000  ; Check if the Y vel is negative
    cmp #%00001000
    beq negative_y
        lda vel         ; Not negative
        and #%00001111  ; Extract the Y vel from the byte
        jmp cont_y
    negative_y:
        lda vel
        and #%00001111
        ora #%11110000  ; Make Y a 8 bit signed integer instead of 4
    cont_y:
    clc
    adc ball_y
    sta ball_y

    ; Change the X position
    lda vel
    and #%10000000  ; Check if the X vel is negative
    cmp #%10000000
    beq negative_x
        lda vel         ; Shift the X vel to the lower bit
        lsr A
        lsr A
        lsr A
        lsr A
        jmp cont_x
    negative_x:
        lda vel
        lsr A
        lsr A
        lsr A
        lsr A
        ora #%11110000  ; Make X a 8 bit signed integer instead of 4
    cont_x:
    clc
    adc ball_x
    sta ball_x

    ; Wall collision check
    ; Check if the ball's y_pos is between 16 <= Y < 208
    ; Set the Y velocity to negative if the ball collides with the wall
    ldx ball_y
    ldy #14    ; Y position to set the ball if it goes past the screen
    cpx #14    ; Check if the Y position is less than 14
    bcc change_vel_y
        ldy #210
        ldx ball_y
        cpx #210   ; Check if the Y position is greater than 210
        bcs change_vel_y
        jmp cont_vel_y
    change_vel_y:
        sty ball_y
        lda vel
        and #%00001111
        eor #$FF
        clc
        adc #%00000001
        and #%00001111
        sta temp_vel
        lda vel
        and #%11110000
        ora temp_vel
        sta vel
    cont_vel_y:

    ; Check if the ball has hit the left/right edge of the screen
    ; Reset its position if it has
    ldx ball_x
    cpx #12    ; Check if the X position is less than 12
    bcc reset_ball
        ldx ball_x
        cpx #228   ; Check if the X position is greater than 228
        bcs reset_ball
        jmp cont_vel_x
    reset_ball:
        ldx #%11010010
        stx vel
        ldx #120
        stx ball_x
        ldx #112
        stx ball_y
    cont_vel_x:

    rts
.endproc

.proc draw_ball
    ; Offset the y position
    ldx ball_y
    dex
    stx drawn_y_pos

    ; Draw upper-left part of ball
    txa
    sta $0200
    ldy #$02  ; Tile index of ball in pattern table
    sty $0201
    lda ball_x
    sta $0203

    ; Draw upper-right part of ball
    lda drawn_y_pos
    sta $0204
    sty $0205
    lda ball_x
    clc
    adc #8
    sta $0207

    ; Draw lower-left part of ball
    lda drawn_y_pos
    clc
    adc #8
    sta $0208
    sty $0209
    lda ball_x
    sta $020B

    ; Draw lower-right part of ball
    lda drawn_y_pos
    clc
    adc #8
    sta $020C
    sty $020D
    lda ball_x
    clc
    adc #8
    sta $020F

    ; Set the rotation/flipping for each ball tile
    ldx #0
    ldy #$02
    set_flags:
        lda ball,X
        sta $0200,Y
        inx
        iny
        iny
        iny
        iny
        cpy #$15
        bmi set_flags
    
    rts
.endproc

.proc player_ball_collision
    lda ball_x
    cmp #31     ; Check whether the ball has passed player 1 x pos
    bcc passed_x1
        jmp cont1  ; No collision occured
    passed_x1:
        lda player1_y
        sec
        sbc #11
        cmp ball_y
        bcc passed_y1  ; Check if the ball is in between the top and bottom of the paddle
            jmp cont1  ; No collision occured
    passed_y1:
        lda player1_y
        clc
        adc #18
        cmp ball_y
        bcs collision1
            jmp cont1
    collision1:  ; Collision occured
        jsr reverse_X_vel
    cont1:

    lda ball_x
    cmp #210     ; Check whether the ball has passed player 2 x pos
    bcs passed_x2
        jmp cont2
    passed_x2:
        lda player2_y
        sec
        sbc #11
        cmp ball_y
        bcc passed_y2
            jmp cont2
    passed_y2:
        lda player2_y
        clc
        adc #18
        cmp ball_y
        bcs collision2
            jmp cont2
    collision2:
        jsr reverse_X_vel
    cont2:

    rts
.endproc

.proc move_players
    jsr read_controllers

    lda pad1
    ldx player1_y
    and #BTN_UP
    bne player1_up
        lda pad1
        and #BTN_DOWN
        bne player1_down
        jmp player1_cont
    player1_down:
        inx
        inx
        inx
        cpx #200
        bcs set_down1
        jmp player1_cont
        set_down1:
            ldx #200
            jmp player1_cont
    player1_up:
        dex
        dex
        dex
        cpx #16
        bcc set_up1
        jmp player1_cont
        set_up1:
            ldx #16
    player1_cont:
    stx player1_y

    lda pad2
    ldx player2_y
    and #BTN_UP
    bne player2_up
        lda pad2
        and #BTN_DOWN
        bne player2_down
        jmp player2_cont
    player2_down:
        inx
        inx
        inx
        cpx #200
        bcs set_down2
        jmp player2_cont
        set_down2:
            ldx #200
            jmp player2_cont
    player2_up:
        dex
        dex
        dex
        cpx #16
        bcc set_up2
        jmp player2_cont
        set_up2:
            ldx #16
    player2_cont:
    stx player2_y

    rts
.endproc

.proc draw_players
    ldx player1_y
    dex
    txa
    ldy #$10  ; Low bit address for player1
    player1:
        sta $0200,Y
        clc
        adc #8
        sta drawn_y_pos
        iny
        lda #$01
        sta $0200,Y
        iny
        lda #$00
        sta $0200,Y
        iny
        lda #24         ; X position of player 1
        sta $0200,Y
        iny
        lda drawn_y_pos

        cpy #$1C
        bne player1

    ldx player2_y
    dex
    txa
    player2:
        sta $0200,Y
        clc
        adc #8
        sta drawn_y_pos
        iny
        lda #$01
        sta $0200,Y
        iny
        lda #%01000000
        sta $0200,Y
        iny
        lda #224        ; X position of player 2
        sta $0200,Y
        iny
        lda drawn_y_pos

        cpy #$28
        bne player2

    rts
.endproc

.proc read_controllers
    ; Initialize the controllers
    lda #$01
    sta CONTROLLER1
    lda #$00
    sta CONTROLLER1

    lda #%00000001
    sta pad1
    sta pad2

    read_pad1:
        lda CONTROLLER1
        lsr A
        rol pad1
        bcc read_pad1

    read_pad2:
        lda CONTROLLER2
        lsr A
        rol pad2
        bcc read_pad2
    
    rts
.endproc

; Reverse the X velocity
; No need for a Y velocity variant as it is only used once
.proc reverse_X_vel
    lda vel
    and #%11110000
    eor #$FF
    clc
    adc #%00010000
    and #%11110000
    sta temp_vel
    lda vel
    and #%00001111
    ora temp_vel
    sta vel

    rts
.endproc

.import irq_handler
.import nmi_handler
.import reset_handler

.export main
.proc main
    ldx PPUSTATUS
    ldx #$3F
    stx PPUADDR
    ldx #$00
    stx PPUADDR
    ldx #$3F
    stx PPUDATA
    lda #$30
    sta PPUDATA
    sta PPUDATA
    sta PPUDATA

    ldx PPUSTATUS
    ldx #$3F
    stx PPUADDR
    ldx #$11
    stx PPUADDR
    lda #$30
    sta PPUDATA
    sta PPUDATA
    sta PPUDATA

    ; Set the ball velocity to (3, 2) and it's position (120, 112)
    ldx #%11010010
    stx vel
    ldx #120
    stx ball_x
    ldx #112
    stx ball_y

    ; Set the player Y position
    ldx #108
    stx player1_y
    stx player2_y

    ; Set ball_collide to false
    ldx #%00000001
    stx ball_collide

    ; Draw the border and ball
    jsr draw_border
    jsr draw_ball

    ldx #0
    stx frame_counter

game_loop:
    ; Move the ball once every 2 frames
    ldx frame_counter
    inx
    cpx #2
    beq move_ball_jmp
        jmp continue
    move_ball_jmp:
        jsr move_ball
        jsr move_players
        jsr player_ball_collision
        ldx #0
    continue:
    stx frame_counter


    jsr draw_ball
    jsr draw_players
    jsr update_screen
    jmp game_loop

.endproc

.segment "ZEROPAGE"

.segment "RODATA"
ball:
    .byte $00        ; Upper left
    .byte %01000000  ; Upper right
    .byte %10000000  ; Lower left
    .byte %11000000  ; Lower right

border_corners:
    .byte $20, $21
    .byte $20, $3E
    .byte $23, $81
    .byte $23, $9E

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "graphics.chr"