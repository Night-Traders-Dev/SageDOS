# renderer.sage — SageDoom terminal raycasting renderer
# ANSI true-color rendering engine for the terminal.
from math_util import clamp, floor_approx, atan2_approx
from map       import Level

class Renderer:
    proc init(self, level, screen_w, view_h):
        self.level     = level
        self.screen_w  = screen_w   # columns in terminal
        self.view_h    = view_h     # rows for 3D view (rest for HUD)
        self.half_h    = floor_approx(view_h / 2.0)

    # ---------------------------------------------------------------
    # DDA raycasting → wall type + perpendicular distance
    # ---------------------------------------------------------------

    proc cast_ray(self, pos_x, pos_y, ray_dir_x, ray_dir_y):
        # Which grid cell we're in
        let map_x = int(math.floor(pos_x))
        let map_y = int(math.floor(pos_y))

        # DDA step distances
        let dd_x = 1.0e30
        let dd_y = 1.0e30
        if ray_dir_x != 0.0:
            dd_x = abs(1.0 / ray_dir_x)
        if ray_dir_y != 0.0:
            dd_y = abs(1.0 / ray_dir_y)

        # Step direction and initial side distances
        let step_x = 0
        let side_x = 0.0
        if ray_dir_x < 0.0:
            step_x = -1
            side_x = (pos_x - map_x) * dd_x
        else:
            step_x = 1
            side_x = (map_x + 1.0 - pos_x) * dd_x

        let step_y = 0
        let side_y = 0.0
        if ray_dir_y < 0.0:
            step_y = -1
            side_y = (pos_y - map_y) * dd_y
        else:
            step_y = 1
            side_y = (map_y + 1.0 - pos_y) * dd_y

        # DDA loop
        let hit     = 0
        let side    = 0   # 0=vertical wall, 1=horizontal wall
        let perp    = 0.0
        let max_steps = 64

        let steps = 0
        while steps < max_steps:
            if side_x < side_y:
                side_x = side_x + dd_x
                map_x = map_x + step_x
                side = 0
            else:
                side_y = side_y + dd_y
                map_y = map_y + step_y
                side = 1

            if self.level.get_cell(map_x, map_y) != 0:
                hit = self.level.get_cell(map_x, map_y)
                if side == 0:
                    perp = (map_x - pos_x + (1.0 - step_x) / 2.0) / ray_dir_x
                else:
                    perp = (map_y - pos_y + (1.0 - step_y) / 2.0) / ray_dir_y
                break
            steps = steps + 1

        return (hit, perp, side)

    # ---------------------------------------------------------------
    # Build one frame as a string
    # ---------------------------------------------------------------

    proc render_frame(self, pos_x, pos_y, dir_x, dir_y, plane_x, plane_y, hp, ammo):
        let w = self.screen_w
        let h = self.view_h
        let half_h = self.half_h

        let wall_types = []
        let wall_dists = []
        let wall_sides = []

        let i = 0
        while i < w:
            let camera_x = 2.0 * i / w - 1.0
            let ray_x = dir_x + plane_x * camera_x
            let ray_y = dir_y + plane_y * camera_x

            let result = self.cast_ray(pos_x, pos_y, ray_x, ray_y)
            push(wall_types, result[0])
            # Avoid fisheye by using perpendicular distance
            let perp_dist = result[1]
            push(wall_dists, perp_dist)
            push(wall_sides, result[2])
            i = i + 1

        # Build output string
        let out = "\033[H"   # cursor home (no clear for speed)
        let ceiling_r = 10
        let ceiling_g = 10
        let ceiling_b = 30
        let floor_r = 30
        let floor_g = 20
        let floor_b = 10

        # Build each row
        let row = 0
        while row < h:
            let line = ""
            let col = 0
            while col < w:
                let wall_type = wall_types[col]
                let perp = wall_dists[col]

                if wall_type == 0:
                    # No wall hit → ceiling/floor gradient
                    let shade_r = ceiling_r
                    let shade_g = ceiling_g
                    let shade_b = ceiling_b
                    line = line + "\033[48;2;" + str(shade_r) + ";" + str(shade_g) + ";" + str(shade_b) + "m "
                    col = col + 1
                    continue

                # Wall height on screen
                let wall_h = 0.0
                if perp > 0.0001:
                    wall_h = h / perp
                let wall_top = half_h - math.floor(wall_h / 2.0)
                let wall_bot = half_h + math.floor(wall_h / 2.0)

                if row < wall_top:
                    # Ceiling
                    let dist_factor = clamp((half_h - row) / (half_h + 1.0), 0.0, 1.0)
                    let r = int(ceiling_r * dist_factor)
                    let g = int(ceiling_g * dist_factor)
                    let b = int(ceiling_b * dist_factor)
                    line = line + "\033[48;2;" + str(r) + ";" + str(g) + ";" + str(b) + "m "
                elif row > wall_bot:
                    # Floor
                    let dist_factor = clamp((row - half_h) / (half_h + 1.0), 0.0, 1.0)
                    let r = int(floor_r * (1.0 - dist_factor))
                    let g = int(floor_g * (1.0 - dist_factor))
                    let b = int(floor_b * (1.0 - dist_factor))
                    line = line + "\033[48;2;" + str(r) + ";" + str(g) + ";" + str(b) + "m "
                else:
                    # Wall with distance shading
                    let base = self.level.get_color(wall_type)
                    let shade = clamp(1.0 - perp / 12.0, 0.05, 1.0)
                    # Horizontal walls are slightly darker (classic DOOM)
                    let side_dark = 1.0
                    if wall_sides[col] == 1:
                        side_dark = 0.7
                    let r = int(base[0] * shade * side_dark)
                    let g = int(base[1] * shade * side_dark)
                    let b = int(base[2] * shade * side_dark)
                    line = line + "\033[48;2;" + str(r) + ";" + str(g) + ";" + str(b) + "m "

                col = col + 1
            line = line + "\033[0m"
            out = out + line
            row = row + 1

        # HUD row
        let hud1 = "\033[48;2;0;0;0m\033[37m"
        let hp_str = " HP: " + str(hp) + " "
        let ammo_str = " AMMO: " + str(ammo) + " "
        hud1 = hud1 + hp_str + ammo_str
        hud1 = hud1 + " SageDoom v0.1 — WASD:move QE:turn EXIT:quit  "
        # Pad to full width
        while len(hud1) < w + 20:
            hud1 = hud1 + " "
        hud1 = hud1 + "\033[0m"
        out = out + hud1

        # Second HUD row
        let hud2 = "\033[48;2;0;0;0m\033[32m"
        let map_x_str = " X:" + str(int(math.floor(pos_x * 10)) / 10.0)
        let map_y_str = " Y:" + str(int(math.floor(pos_y * 10)) / 10.0)
        let dir_str  = " DIR:" + str(int(math.floor(math.atan2(dir_y, dir_x) * 180.0 / math.pi)))
        hud2 = hud2 + map_x_str + map_y_str + dir_str + "°  "
        while len(hud2) < w + 20:
            hud2 = hud2 + " "
        hud2 = hud2 + "\033[0m"
        out = out + hud2

        return out
