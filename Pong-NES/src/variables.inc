; Positional variables
vel           = $00  ; NXXX NYYY
ball_x        = $01  ; X position of ball
ball_y        = $02  ; Y position of ball
player1_y     = $03  ; Y position of player 1
player2_y     = $04  ; Y position of player 2
ball_collide  = $05  ; Disable collisions when true

frame_counter = $06  ; Used to controll when the ball should move

; Controller variable
pad1          = $07
pad2          = $08

; Temporary variables for quick calculations
temp_vel      = $0A
drawn_y_pos   = $0B  ; Y position to draw to - usually y_pos-1