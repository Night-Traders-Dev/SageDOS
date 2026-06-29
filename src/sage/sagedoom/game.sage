# game.sage — SageDoom game engine
# Player state, movement, collision detection, and game loop.
from math_util import atan2_approx
from player    import PlayerState, move_forward, move_backward, strafe_left, strafe_right, rotate_player
from renderer  import Renderer
from map       import Level, E1M1_MAP

# ---------------------------------------------------------------
# Game loop
# ---------------------------------------------------------------

class Game:
    proc init(self, screen_w, screen_h):
        self.screen_w  = screen_w
        self.screen_h  = screen_h
        self.view_h    = screen_h - 2
        self.level     = Level(E1M1_MAP)
        self.player    = PlayerState()
        self.renderer  = Renderer(self.level, screen_w, self.view_h)
        self.running   = true
        self.frame     = 0

    proc clear_screen(self):
        print "\033[2J\033[H"

    proc run_step(self, cmd):
        let dt = 0.05
        let p = self.player
        let lvl = self.level

        let key = upper(strip(cmd))
        if key == "W":
            move_forward(p, lvl, dt)
        elif key == "S":
            move_backward(p, lvl, dt)
        elif key == "A":
            strafe_left(p, lvl, dt)
        elif key == "D":
            strafe_right(p, lvl, dt)
        elif key == "Q":
            rotate_player(p, -p.rot_speed * dt)
        elif key == "E":
            rotate_player(p, p.rot_speed * dt)
        elif key == "EXIT" or key == "QUIT" or key == "":
            self.running = false
            return

        let frame_str = self.renderer.render_frame(
            p.pos_x, p.pos_y, p.dir_x, p.dir_y,
            p.plane_x, p.plane_y, p.hp, p.ammo
        )
        print frame_str
        self.frame = self.frame + 1

    proc run_interactive(self):
        self.clear_screen()
        print "\033[?25l"

        print "=== SageDoom v0.1 — Terminal Raycaster ==="
        print "W=forward S=back A=left D=right Q=turn-left E=turn-right"
        print "Type EXIT or QUIT to quit. Press Enter after each key."
        print ""

        let p = self.player
        let frame_str = self.renderer.render_frame(
            p.pos_x, p.pos_y, p.dir_x, p.dir_y,
            p.plane_x, p.plane_y, p.hp, p.ammo
        )
        print frame_str

        while self.running:
            let raw = input("> ")
            self.run_step(raw)

        print "\033[?25h"
        print "\033[2J\033[H"
        print "SageDoom: Game exited. Frames rendered: " + str(self.frame)
