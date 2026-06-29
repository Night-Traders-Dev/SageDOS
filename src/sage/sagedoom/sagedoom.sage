# sagedoom.sage — SageDoom terminal raycasting engine (single-file AOT build)
# Pure SageLang Wolfenstein-3D-style engine with ANSI terminal rendering.

# ==================================================================
# Math utilities (Taylor-series trig approximations for AOT compat)
# ==================================================================

proc abs_val(x):
    if x < 0.0: return -x
    return x

proc sin_approx(x):
    let pi = 3.141592653589793
    while x > pi: x = x - 2.0 * pi
    while x < -pi: x = x + 2.0 * pi
    let x2 = x * x
    return x * (1.0 - x2 * (1.0/6.0 - x2 * 1.0/120.0))

proc cos_approx(x):
    return sin_approx(1.5707963267948966 - x)

proc tan_approx(x):
    let c = cos_approx(x)
    if c < 0.000001 and c > -0.000001: return 1000000.0
    return sin_approx(x) / c

proc clamp(val, lo, hi):
    if val < lo: return lo
    if val > hi: return hi
    return val

proc deg_to_rad(deg):
    return deg * 3.141592653589793 / 180.0

proc rotate_vec(x, y, angle):
    let c = cos_approx(angle)
    let s = sin_approx(angle)
    return (x * c - y * s, x * s + y * c)

proc floor_approx(x):
    let i = int(x)
    if x < 0.0 and x != i: return i - 1
    return i

# ==================================================================
# Level data
# ==================================================================

let E1M1_MAP = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1],
    [1, 0, 0, 2, 0, 0, 0, 0, 0, 3, 3, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 3, 3, 3, 0, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
]

let WALL_COLORS = [
    [0,   0,   0  ],
    [80,  80,  80 ],
    [60,  30,  20 ],
    [20,  40,  60 ],
    [70,  10,  10 ],
]

proc map_get_cell(map, x, y):
    let w = len(map[0])
    let h = len(map)
    let gx = floor_approx(x)
    let gy = floor_approx(y)
    if gx < 0 or gx >= w or gy < 0 or gy >= h: return 0
    return map[gy][gx]

proc map_is_solid(map, x, y):
    return map_get_cell(map, x, y) != 0

# ==================================================================
# Player state
# ==================================================================

class Player:
    proc init(self):
        self.pos_x = 3.0
        self.pos_y = 3.0
        let rad = 0.0
        self.dir_x   = cos_approx(rad)
        self.dir_y   = sin_approx(rad)
        let fov_rad  = deg_to_rad(66.0)
        let plane_len = tan_approx(fov_rad / 2.0)
        self.plane_x = -self.dir_y * plane_len
        self.plane_y =  self.dir_x * plane_len
        self.hp       = 100
        self.ammo     = 50
        self.move_speed = 3.5
        self.rot_speed  = 2.5

proc player_move_forward(p, map, dt):
    let nx = p.pos_x + p.dir_x * p.move_speed * dt
    let ny = p.pos_y + p.dir_y * p.move_speed * dt
    if not map_is_solid(map, nx, p.pos_y): p.pos_x = nx
    if not map_is_solid(map, p.pos_x, ny): p.pos_y = ny

proc player_move_back(p, map, dt):
    let nx = p.pos_x - p.dir_x * p.move_speed * dt
    let ny = p.pos_y - p.dir_y * p.move_speed * dt
    if not map_is_solid(map, nx, p.pos_y): p.pos_x = nx
    if not map_is_solid(map, p.pos_x, ny): p.pos_y = ny

proc player_strafe_left(p, map, dt):
    let nx = p.pos_x - p.dir_y * p.move_speed * dt
    let ny = p.pos_y + p.dir_x * p.move_speed * dt
    if not map_is_solid(map, nx, p.pos_y): p.pos_x = nx
    if not map_is_solid(map, p.pos_x, ny): p.pos_y = ny

proc player_strafe_right(p, map, dt):
    let nx = p.pos_x + p.dir_y * p.move_speed * dt
    let ny = p.pos_y - p.dir_x * p.move_speed * dt
    if not map_is_solid(map, nx, p.pos_y): p.pos_x = nx
    if not map_is_solid(map, p.pos_x, ny): p.pos_y = ny

proc player_rotate(p, angle):
    let nd = rotate_vec(p.dir_x, p.dir_y, angle)
    p.dir_x = nd[0]
    p.dir_y = nd[1]
    let np = rotate_vec(p.plane_x, p.plane_y, angle)
    p.plane_x = np[0]
    p.plane_y = np[1]

# ==================================================================
# DDA Raycaster
# ==================================================================

proc cast_ray(map, pos_x, pos_y, ray_dir_x, ray_dir_y):
    let map_x = floor_approx(pos_x)
    let map_y = floor_approx(pos_y)

    let dd_x = 1.0e30
    let dd_y = 1.0e30
    if ray_dir_x != 0.0: dd_x = abs_val(1.0 / ray_dir_x)
    if ray_dir_y != 0.0: dd_y = abs_val(1.0 / ray_dir_y)

    let step_x = 0
    let side_x = 0.0
    let step_y = 0
    let side_y = 0.0

    if ray_dir_x < 0.0:
        step_x = -1
        side_x = (pos_x - map_x) * dd_x
    else:
        step_x = 1
        side_x = (map_x + 1.0 - pos_x) * dd_x

    if ray_dir_y < 0.0:
        step_y = -1
        side_y = (pos_y - map_y) * dd_y
    else:
        step_y = 1
        side_y = (map_y + 1.0 - pos_y) * dd_y

    let hit = 0
    let side = 0
    let perp = 0.0
    let steps = 0

    while steps < 64:
        if side_x < side_y:
            side_x = side_x + dd_x
            map_x = map_x + step_x
            side = 0
        else:
            side_y = side_y + dd_y
            map_y = map_y + step_y
            side = 1

        hit = map_get_cell(map, map_x, map_y)
        if hit != 0:
            if side == 0:
                perp = (map_x - pos_x + (1.0 - step_x) / 2.0) / ray_dir_x
            else:
                perp = (map_y - pos_y + (1.0 - step_y) / 2.0) / ray_dir_y
            break
        steps = steps + 1

    return (hit, perp, side)

# ==================================================================
# Renderer
# ==================================================================

proc render_frame(map, p, screen_w, view_h):
    let half_h = floor_approx(view_h / 2.0)
    let colors = WALL_COLORS

    # Cast all rays
    let wall_types = []
    let wall_dists = []
    let wall_sides = []
    let i = 0
    while i < screen_w:
        let cam_x = 2.0 * i / screen_w - 1.0
        let rx = p.dir_x + p.plane_x * cam_x
        let ry = p.dir_y + p.plane_y * cam_x
        let result = cast_ray(map, p.pos_x, p.pos_y, rx, ry)
        push(wall_types, result[0])
        push(wall_dists, result[1])
        push(wall_sides, result[2])
        i = i + 1

    # Output directly via print (row by row) to avoid OOM in AOT mode
    print "\033[H"

    let row = 0
    while row < view_h:
        let line = ""
        let col = 0
        while col < screen_w:
            let wt = wall_types[col]
            let perp = wall_dists[col]
            let side_bit = wall_sides[col]

            if wt == 0:
                line = line + "\033[48;2;10;10;30m "
                col = col + 1
                continue

            let wall_h = 0.0
            if perp > 0.0001: wall_h = view_h / perp
            let wall_top = half_h - floor_approx(wall_h / 2.0)
            let wall_bot = half_h + floor_approx(wall_h / 2.0)

            if row < wall_top:
                let df = clamp((half_h - row) / (half_h + 1.0), 0.0, 1.0)
                let r = int(10 * df)
                let g = int(10 * df)
                let b = int(30 * df)
                line = line + "\033[48;2;" + str(r) + ";" + str(g) + ";" + str(b) + "m "
            elif row > wall_bot:
                let df = clamp((row - half_h) / (half_h + 1.0), 0.0, 1.0)
                let r = int(30 * (1.0 - df))
                let g = int(20 * (1.0 - df))
                let b = int(10 * (1.0 - df))
                line = line + "\033[48;2;" + str(r) + ";" + str(g) + ";" + str(b) + "m "
            else:
                let base = colors[wt]
                let shade = clamp(1.0 - perp / 12.0, 0.05, 1.0)
                let sd = 1.0
                if side_bit == 1: sd = 0.7
                let r = int(base[0] * shade * sd)
                let g = int(base[1] * shade * sd)
                let b = int(base[2] * shade * sd)
                line = line + "\033[48;2;" + str(r) + ";" + str(g) + ";" + str(b) + "m "
            col = col + 1
        print line + "\033[0m"
        row = row + 1

    # HUD row
    print "\033[48;2;0;0;0m\033[37m HP:" + str(p.hp) + " AMMO:" + str(p.ammo) + "  SageDoom v0.1  WASD:move QE:turn EXIT:quit\033[0m"

# ==================================================================
# Game loop
# ==================================================================

proc run_game(screen_w, screen_h):
    let view_h = screen_h - 2
    let map = E1M1_MAP
    let p = Player()

    print "\033[2J\033[H\033[?25l"
    print "=== SageDoom v0.1 — Terminal Raycaster ==="
    print "W=forward S=back A=left D=right Q=turn-left E=turn-right"
    print "Type EXIT or QUIT to quit. Press Enter after each key."
    print ""

    # Initial frame
    render_frame(map, p, screen_w, view_h)

    let running = true
    let frames = 0
    let dt = 0.05

    while running:
        let raw = input("> ")
        let key = upper(strip(raw))

        if key == "W":
            player_move_forward(p, map, dt)
        elif key == "S":
            player_move_back(p, map, dt)
        elif key == "A":
            player_strafe_left(p, map, dt)
        elif key == "D":
            player_strafe_right(p, map, dt)
        elif key == "Q":
            player_rotate(p, -p.rot_speed * dt)
        elif key == "E":
            player_rotate(p, p.rot_speed * dt)
        elif key == "EXIT" or key == "QUIT" or key == "":
            running = false
            break
        else:
            continue

        render_frame(map, p, screen_w, view_h)
        frames = frames + 1

    print "\033[?25h\033[2J\033[H"
    print "SageDoom exited. Frames: " + str(frames)

# ==================================================================
# Entry point
# ==================================================================

import sys

let scr_w = 80
let scr_h = 24

let args = sys.args()
if len(args) > 1: scr_w = tonumber(args[1])
if len(args) > 2: scr_h = tonumber(args[2])
if scr_w < 40: scr_w = 40
if scr_h < 12: scr_h = 12

run_game(scr_w, scr_h)
