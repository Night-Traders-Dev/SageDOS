# player.sage — SageDoom player state and movement
from math_util import cos_approx, sin_approx, tan_approx, rotate_vec

class PlayerState:
    proc init(self):
        self.pos_x = 3.0
        self.pos_y = 3.0
        let rad = 0.0
        self.dir_x   = cos_approx(rad)
        self.dir_y   = sin_approx(rad)
        let fov_rad  = 66.0 * 3.141592653589793 / 180.0
        let plane_len = tan_approx(fov_rad / 2.0)
        self.plane_x = -self.dir_y * plane_len
        self.plane_y =  self.dir_x * plane_len
        self.hp       = 100
        self.ammo     = 50
        self.move_speed = 3.5
        self.rot_speed  = 2.5

proc move_forward(p, level, dt):
    let new_x = p.pos_x + p.dir_x * p.move_speed * dt
    let new_y = p.pos_y + p.dir_y * p.move_speed * dt
    if not level.is_solid(new_x, p.pos_y):
        p.pos_x = new_x
    if not level.is_solid(p.pos_x, new_y):
        p.pos_y = new_y

proc move_backward(p, level, dt):
    let new_x = p.pos_x - p.dir_x * p.move_speed * dt
    let new_y = p.pos_y - p.dir_y * p.move_speed * dt
    if not level.is_solid(new_x, p.pos_y):
        p.pos_x = new_x
    if not level.is_solid(p.pos_x, new_y):
        p.pos_y = new_y

proc strafe_left(p, level, dt):
    let new_x = p.pos_x - p.dir_y * p.move_speed * dt
    let new_y = p.pos_y + p.dir_x * p.move_speed * dt
    if not level.is_solid(new_x, p.pos_y):
        p.pos_x = new_x
    if not level.is_solid(p.pos_x, new_y):
        p.pos_y = new_y

proc strafe_right(p, level, dt):
    let new_x = p.pos_x + p.dir_y * p.move_speed * dt
    let new_y = p.pos_y - p.dir_x * p.move_speed * dt
    if not level.is_solid(new_x, p.pos_y):
        p.pos_x = new_x
    if not level.is_solid(p.pos_x, new_y):
        p.pos_y = new_y

proc rotate_player(p, angle):
    let nd = rotate_vec(p.dir_x, p.dir_y, angle)
    p.dir_x = nd[0]
    p.dir_y = nd[1]
    let np = rotate_vec(p.plane_x, p.plane_y, angle)
    p.plane_x = np[0]
    p.plane_y = np[1]
