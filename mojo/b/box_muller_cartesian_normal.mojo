from std.ffi import c_size_t
from std.math import cos, isfinite, log, sin, sqrt, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_PAIRS = 64
comptime DRAW_SCALE = 4_294_967_296.0
comptime TAU = 6.283185307179586476925286766559

fn box_muller_is_bounded_integer(value: Float64, minimum: Float64, maximum: Float64) -> Bool:
    return isfinite(value) and trunc(value) == value and value >= minimum and value <= maximum

@export("box_muller_cartesian_normal")
fn box_muller_cartesian_normal(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 2 or length > 1 + 2 * MAX_PAIRS:
        return -1
    if not box_muller_is_bounded_integer(input[0], 1.0, Float64(MAX_PAIRS)):
        return -1
    let pair_count = Int(input[0])
    if length != c_size_t(1 + 2 * pair_count):
        return -1
    for index in range(2 * pair_count):
        if not box_muller_is_bounded_integer(input[1 + index], 0.0, 4_294_967_295.0):
            return -1

    let result_count = 2 * pair_count
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(result_count):
        return -2
    for pair in range(pair_count):
        let radial = (input[1 + 2 * pair] + 1.0) / DRAW_SCALE
        let angular = input[2 + 2 * pair] / DRAW_SCALE
        let radius = sqrt(-2.0 * log(radial))
        let angle = TAU * angular
        output[2 * pair] = radius * cos(angle)
        output[2 * pair + 1] = radius * sin(angle)
    return Int64(result_count)
