# math_util.sage — SageDoom math utilities (no external dependencies)
# Pure-Sage approximations for AOT compatibility.

# ---------------------------------------------------------------
# Trig approximations (Taylor series)
# ---------------------------------------------------------------

proc sin_approx(x):
    # Range reduction to [-pi, pi]
    let pi = 3.141592653589793
    while x > pi:
        x = x - 2.0 * pi
    while x < -pi:
        x = x + 2.0 * pi
    # Taylor: x - x^3/6 + x^5/120
    let x2 = x * x
    return x * (1.0 - x2 * (1.0/6.0 - x2 * 1.0/120.0))

proc cos_approx(x):
    return sin_approx(1.5707963267948966 - x)

proc tan_approx(x):
    let c = cos_approx(x)
    if c < 0.000001 and c > -0.000001:
        return 1000000.0
    return sin_approx(x) / c

# ---------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------

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

proc atan2_approx(y, x):
    if x > 0.0:
        return sin_approx(y / (x + 0.0001))
    if x < 0.0:
        if y >= 0.0:
            return 3.141592653589793 + sin_approx(y / (x - 0.0001))
        return -3.141592653589793 + sin_approx(y / (x - 0.0001))
    if y > 0.0: return 1.5707963267948966
    if y < 0.0: return -1.5707963267948966
    return 0.0

proc floor_approx(x):
    let i = int(x)
    if x < 0.0 and x != i:
        return i - 1
    return i
