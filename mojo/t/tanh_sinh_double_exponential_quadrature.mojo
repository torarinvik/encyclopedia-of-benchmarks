from std.ffi import c_size_t
from std.math import exp, isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_PARSEABLE_INPUT_LENGTH = 3
comptime PI_PINNED = 3.14159265358979323846264338327950288

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    return Float64(Int(value)) == value

fn integrate(function_id: Int, p: Int) -> Float64:
    let h = 1.0 / Float64(1 << p)
    let half_pi = PI_PINNED / 2.0
    let limit = 3 * (1 << p)
    var total = 0.0
    for j in range(-limit, limit + 1):
        let t = Float64(j) * h
        let exp_t = exp(t)
        let exp_minus_t = exp(-t)
        let sinh_t = (exp_t - exp_minus_t) * 0.5
        let cosh_t = (exp_t + exp_minus_t) * 0.5
        let u = half_pi * sinh_t
        let abs_u = -u if u < 0.0 else u
        let q = exp(-2.0 * abs_u)
        let one_plus_q = 1.0 + q
        let sech_squared = (4.0 * q) / (one_plus_q * one_plus_q)
        let magnitude_x = (1.0 - q) / one_plus_q
        let x = magnitude_x if u >= 0.0 else -magnitude_x
        let jacobian = (half_pi * cosh_t) * sech_squared
        var sample = 0.0
        if function_id == 0:
            sample = 1.0
        elif function_id == 1:
            sample = x * x
        elif function_id == 2:
            sample = 1.0 / sqrt(sech_squared)
        elif u >= 0.0:
            sample = 1.0 / sqrt((2.0 * q) / one_plus_q)
        else:
            sample = 1.0 / sqrt(2.0 / one_plus_q)
        let transformed = sample * jacobian
        total += h * transformed
    return total

@export("tanh_sinh_double_exponential_quadrature")
fn tanh_sinh_double_exponential_quadrature(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH: return -1
    if input_length != 2 or not exact_integer(input[0], 0, 3) or not exact_integer(input[1], 2, 4): return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1: return -2
    let value = integrate(Int(input[0]), Int(input[1]))
    if not isfinite(value): return -1
    output[0] = value
    return 1
