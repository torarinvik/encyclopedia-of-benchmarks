from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INPUT_LENGTH = 6

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    return Float64(Int(value)) == value

fn polynomial(id: Int, x: Float64) -> Float64:
    if id == 0: return x*x-2.0
    if id == 1: return x*x*x-2.0
    if id == 2: return x*x*x+x-1.0
    return x

fn opposite(a: Float64, b: Float64) -> Bool:
    return (a < 0.0) != (b < 0.0)

fn ridders_root_finding(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length != 5 or input_length > MAX_INPUT_LENGTH: return -1
    let raw_id = input[0]
    let raw_left = input[1]
    let raw_right = input[2]
    let raw_tolerance = input[3]
    let raw_iterations = input[4]
    if not exact_integer(raw_id, 0, 3) or not exact_integer(raw_left, -3000, 3000) or not exact_integer(raw_right, -3000, 3000) or not exact_integer(raw_tolerance, 1, 1000) or not exact_integer(raw_iterations, 24, 32): return -1
    let function_id = Int(raw_id)
    let left_milli = Int(raw_left)
    let right_milli = Int(raw_right)
    let tolerance_micro = Int(raw_tolerance)
    let iterations = Int(raw_iterations)
    if left_milli >= right_milli: return -1
    var left = Float64(left_milli)/1000.0
    var right = Float64(right_milli)/1000.0
    var f_left = polynomial(function_id, left)
    var f_right = polynomial(function_id, right)
    if f_left != 0.0 and f_right != 0.0 and not opposite(f_left, f_right): return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1: return -2
    if f_left == 0.0:
        output[0] = left
        return 1
    if f_right == 0.0:
        output[0] = right
        return 1
    let tolerance = Float64(tolerance_micro)/1_000_000.0
    for _ in range(iterations):
        if right-left <= tolerance:
            output[0] = (left+right)*0.5
            return 1
        let middle = (left+right)*0.5
        let f_middle = polynomial(function_id, middle)
        if f_middle == 0.0:
            output[0] = middle
            return 1
        let radicand = f_middle*f_middle-f_left*f_right
        if not isfinite(radicand) or radicand <= 0.0: return -3
        let denominator = sqrt(radicand)
        if not isfinite(denominator) or denominator == 0.0: return -3
        let direction = -1.0 if f_left < f_right else 1.0
        let candidate = middle+(middle-left)*direction*f_middle/denominator
        if not isfinite(candidate) or candidate <= left or candidate >= right: return -3
        let f_candidate = polynomial(function_id, candidate)
        if f_candidate == 0.0:
            output[0] = candidate
            return 1
        if opposite(f_left, f_candidate):
            right = candidate
            f_right = f_candidate
        else:
            left = candidate
            f_left = f_candidate
        if right-left <= tolerance:
            output[0] = (left+right)*0.5
            return 1
    return -3

@export("ridders_root_finding")
fn ridders_root_finding_export(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    return ridders_root_finding(input, input_length, output, output_capacity)
