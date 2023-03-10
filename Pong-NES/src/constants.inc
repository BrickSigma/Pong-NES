; Registers
PPUCTRL     = $2000  ; PPU controller
PPUMASK     = $2001  ; Instructs when/how to update the screen
PPUSTATUS   = $2002  ; Used to reset the PPUADDR
PPUSCROLL   = $2005
PPUADDR     = $2006
PPUDATA     = $2007
OAMADDR     = $2003  ; Low bit address of the OAM in CPU
OAMDMA      = $4014  ; High bit address of the OAM in CPU
CONTROLLER1 = $4016
CONTROLLER2 = $4017

; Controller data
BTN_RIGHT   = %00000001
BTN_LEFT    = %00000010
BTN_DOWN    = %00000100
BTN_UP      = %00001000
BTN_START   = %00010000
BTN_SELECT  = %00100000
BTN_B       = %01000000
BTN_A       = %10000000