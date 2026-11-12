from std.ffi import c_size_t
from std.math import isfinite, log, sqrt, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_PAIRS = 4096
comptime MODULUS_MASK: Int64 = 70_368_744_177_663
comptime WORD_MASK: Int64 = 8_388_607
comptime MULTIPLIER: Int64 = 1_220_703_125
comptime MODULUS_SCALE = 70_368_744_177_664.0

fn npb_is_bounded_integer(value: Float64, minimum: Float64, maximum: Float64) -> Bool:
    return isfinite(value) and trunc(value) == value and value >= minimum and value <= maximum

fn npb_advance_state(state: Int64) -> Int64:
    let low = state & WORD_MASK
    let high = state >> 23
    let multiplier_low = MULTIPLIER & WORD_MASK
    let multiplier_high = MULTIPLIER >> 23
    let low_product = low * multiplier_low
    let cross = (low * multiplier_high + high * multiplier_low) & WORD_MASK
    return (low_product + (cross << 23)) & MODULUS_MASK

@export("npb_ep")
fn npb_ep(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2:
        return -1
    if not npb_is_bounded_integer(input[0], 1.0, Float64(MAX_PAIRS)) or
        not npb_is_bounded_integer(input[1], 1.0, 70_368_744_177_663.0):
        return -1
    let pair_count = Int(input[0])
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 12:
        return -2

    var state = Int64(input[1])
    var histogram = InlineArray[Int64, 10]()
    var sum_x: Float64 = 0.0
    var sum_y: Float64 = 0.0
    for _ in range(pair_count):
        state = npb_advance_state(state)
        let x = 2.0 * (Float64(state) / MODULUS_SCALE) - 1.0
        state = npb_advance_state(state)
        let y = 2.0 * (Float64(state) / MODULUS_SCALE) - 1.0
        let radius_squared = x * x + y * y
        if radius_squared <= 0.0 or radius_squared > 1.0:
            continue
        let scale = sqrt(-2.0 * log(radius_squared) / radius_squared)
        let normal_x = x * scale
        let normal_y = y * scale
        let abs_x = if normal_x < 0.0 then -normal_x else normal_x
        let abs_y = if normal_y < 0.0 then -normal_y else normal_y
        let extent = if abs_x > abs_y then abs_x else abs_y
        if extent < 10.0:
            histogram[Int(extent)] += 1
        sum_x += normal_x
        sum_y += normal_y
    for bin in range(10):
        output[bin] = Float64(histogram[bin])
    output[10] = sum_x
    output[11] = sum_y
    return 12
