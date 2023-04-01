import pygame
from pygame.locals import *

pygame.init()

win = pygame.display.set_mode((256*3, 240*3))
canvas = pygame.surface.Surface((256, 240))
clock = pygame.time.Clock()
FPS = 60

ball = [256/2, 240/2]
radius = 6
vel = [-3, 2]

class Player:
    def __init__(self, x, y, up, down):
        self.rect = pygame.Rect(x, y, 8, 24)
        self.up = up
        self.down = down

    def move(self):
        keys = pygame.key.get_pressed()
        if keys[self.up]:
            self.rect.y -= 3
            if self.rect.y < 16:
                self.rect.y = 16
        elif keys[self.down]:
            self.rect.y += 3
            if self.rect.y + 24 > (240-16):
                self.rect.y = 240-16-24

    def draw(self):
        pygame.draw.rect(canvas, (255, 255, 255), self.rect)


player1 = Player(24, 108, K_w, K_s)
player2 = Player(224, 108, K_UP, K_DOWN)

def check_collision(player1: Player, player2: Player, ball, vel):
    if ball[0] < player1.rect.x + 8 + radius:  # 24 + 8 + r(6) -> ball_x < 38
        if ball[1] > player1.rect.y - radius:   # ball_y > p1_y - 6 -> ball_y + 5 >= p1_y
            if ball[1] < player1.rect.y + player1.rect.height + radius:  # ball_y <= p1_y + 29
                vel[0] = abs(vel[0])     

    if ball[0] > player2.rect.x - radius:  # 224 - r(6) -> ball_x > 218
        if ball[1] > player2.rect.y - radius:  # ball_y > p2_y - 6
            if ball[1] < player2.rect.y + player2.rect.height + radius:  # ball_y <= p2_y + 29
                vel[0] = -abs(vel[0])
                
    return vel

def reset():
    global ball, vel
    ball = [256/2, 240/2]
    vel = [-3, 2]


frame_count = 0
run = True
while run:
    for event in pygame.event.get():
        if event.type == QUIT:
            run = False


    if frame_count == 0:
        # Move players
        player1.move()
        player2.move()
        # Move ball
        ball[0] += vel[0]
        ball[1] += vel[1]
        if ball[0]-6 < 16 or ball[0]+6 > 240:
            reset()
        if ball[1] < 22 or ball[1] > 218:
            vel[1] *= -1
        vel = check_collision(player1, player2, ball, vel)
        
    frame_count += 1
    if frame_count % 2 == 0:
        frame_count = 0

    canvas.fill((0, 0, 0))
    pygame.draw.circle(canvas, (255, 255, 255), ball, 6)
    pygame.draw.rect(canvas, (255, 255, 255), pygame.Rect(8, 8, 256-16, 240-16), 8)
    player1.draw()
    player2.draw()
    win.blit(pygame.transform.scale(canvas, (256*3, 240*3)), (0, 0))
    pygame.display.update()

    clock.tick(FPS)

pygame.quit()