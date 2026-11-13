from std.ffi import c_size_t
from std.math import fabs, isfinite, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INPUT_LENGTH = 6

fn sample(function_id: Int, x: Float64) -> Float64:
    if function_id == 0: return x * x * x * x
    if function_id == 1: return sin(x)
    return 1.0 / (1.0 + x * x)

fn simpson(a: Float64, b: Float64, fa: Float64, fm: Float64, fb: Float64) -> Float64:
    return (b - a) * (fa + 4.0 * fm + fb) / 6.0

fn refine(function_id: Int, a: Float64, b: Float64, fa: Float64, fm: Float64,
          fb: Float64, whole: Float64, tolerance: Float64, depth: Int) -> Float64:
    let middle = (a + b) * 0.5
    let left_middle = (a + middle) * 0.5
    let right_middle = (middle + b) * 0.5
    let flm = sample(function_id, left_middle)
    let frm = sample(function_id, right_middle)
    let left = simpson(a, middle, fa, flm, fm)
    let right = simpson(middle, b, fm, frm, fb)
    let delta = left + right - whole
    if depth == 0 or fabs(delta) <= 15.0 * tolerance:
        return left + right + delta / 15.0
    return refine(function_id, a, middle, fa, flm, fm, left, tolerance * 0.5, depth - 1) + refine(function_id, middle, b, fm, frm, fb, right, tolerance * 0.5, depth - 1)

@export("adaptive_simpson_quadrature")
fn adaptive_simpson_quadrature(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length != 5 or input_length > MAX_INPUT_LENGTH: return -1
    let raw_id = input[0]
    let raw_a = input[1]
    let raw_b = input[2]
    let raw_exponent = input[3]
    let raw_depth = input[4]
    if not isfinite(raw_id) or raw_id < 0 or raw_id > 2 or Float64(Int(raw_id)) != raw_id: return -1
    if not isfinite(raw_a) or raw_a < -2000000 or raw_a > 2000000 or Float64(Int(raw_a)) != raw_a: return -1
    if not isfinite(raw_b) or raw_b < -2000000 or raw_b > 2000000 or Float64(Int(raw_b)) != raw_b: return -1
    if not isfinite(raw_exponent) or raw_exponent < 7 or raw_exponent > 8 or Float64(Int(raw_exponent)) != raw_exponent: return -1
    if not isfinite(raw_depth) or raw_depth < 8 or raw_depth > 12 or Float64(Int(raw_depth)) != raw_depth: return -1
    let a_micro = Int(raw_a)
    let b_micro = Int(raw_b)
    if a_micro > b_micro: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1: return -2
    let function_id = Int(raw_id)
    let exponent = Int(raw_exponent)
    let depth = Int(raw_depth)
    let a = Float64(a_micro) / 1000000.0
    let b = Float64(b_micro) / 1000000.0
    var result: Float64 = 0.0
    if a != b:
        let middle = (a + b) * 0.5
        var tolerance: Float64 = 1.0
        for _ in range(exponent): tolerance *= 0.1
        let fa = sample(function_id, a)
        let fm = sample(function_id, middle)
        let fb = sample(function_id, b)
        result = refine(function_id, a, b, fa, fm, fb, simpson(a, b, fa, fm, fb), tolerance, depth)
    if not isfinite(result): return -1
    output[0] = result
    return 1
