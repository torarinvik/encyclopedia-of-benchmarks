from std.ffi import c_size_t
from std.math import isfinite, log, sqrt, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_DRAWS = 128
comptime MAX_ATTEMPTS = 64
comptime DRAW_SCALE = 2_147_483_648.0

fn marsaglia_is_bounded_integer(value: Float64, minimum: Float64, maximum: Float64) -> Bool:
    return isfinite(value) and trunc(value) == value and value >= minimum and value <= maximum

@export("marsaglia_polar_normal")
fn marsaglia_polar_normal(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 4 or length > 2 + MAX_DRAWS:
        return -1
    if not marsaglia_is_bounded_integer(input[0], 2.0, Float64(MAX_DRAWS)) or
        not marsaglia_is_bounded_integer(input[1], 1.0, Float64(MAX_ATTEMPTS)):
        return -1
    let draw_count = Int(input[0])
    let attempt_cap = Int(input[1])
    if (draw_count & 1) != 0 or length != c_size_t(2 + draw_count) or draw_count < 2 * attempt_cap:
        return -1
    for index in range(draw_count):
        if not marsaglia_is_bounded_integer(input[2 + index], 0.0, 4_294_967_295.0):
            return -1

    var first: Float64 = 0.0
    var second: Float64 = 0.0
    var accepted = False
    for attempt in range(attempt_cap):
        let u1 = input[2 + 2 * attempt] / DRAW_SCALE - 1.0
        let u2 = input[3 + 2 * attempt] / DRAW_SCALE - 1.0
        let radius_squared = u1 * u1 + u2 * u2
        if radius_squared <= 0.0 or radius_squared >= 1.0:
            continue
        let scale = sqrt(-2.0 * log(radius_squared) / radius_squared)
        first = u1 * scale
        second = u2 * scale
        accepted = True
        break
    if not accepted:
        return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 2:
        return -2
    output[0] = first
    output[1] = second
    return 2
