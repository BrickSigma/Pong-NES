; Positional variables
x_vel         = $00  ; X velocity of ball
y_vel         = $01  ; Y velocity of ball
ball_x        = $02  ; X position of ball
ball_y        = $03  ; Y position of ball

player1_y     = $04  ; Y position of player 1
player2_y     = $05  ; Y position of player 2

; Time related variables
frame_counter = $06  ; Used to controll when the ball/players should move

; Controller variables
pad1          = $07
pad2          = $08

; Temporary variables for quick calculations or temporary storage
drawn_y_pos   = $09  ; Y position to draw to - usually y_pos-1
drawn_x_pos   = $0A  ; X position of ball corners when drawn
