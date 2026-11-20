from std.ffi import c_size_t
from std.collections import InlineArray
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_DEGREE = 8
alias MAX_ITERATIONS = 4
alias MAX_INPUT_LENGTH = 14
alias MODULUS: Int64 = 998244353

fn bairstow_norm(value_input: Int64) -> Int64:
    var value = value_input % MODULUS
    if value < 0: value += MODULUS
    return value

fn bairstow_power(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = bairstow_norm(base_input)
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result

fn bairstow_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("bairstow_quadratic_factor_iteration")
fn bairstow_quadratic_factor_iteration(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1
            or length > c_size_t(MAX_INPUT_LENGTH): return -1
    let degree_value = input[0]
    if degree_value < 3 or degree_value > MAX_DEGREE: return -1
    let degree = Int(degree_value)
    if length != c_size_t(degree + 5): return -1
    var leading: Int64 = 0
    for i in range(degree + 1):
        let coefficient = input[1 + i]
        if coefficient < 0 or coefficient >= MODULUS: return -1
        if i == degree: leading = coefficient
    let initial_s = input[degree + 2]
    let initial_t = input[degree + 3]
    let iteration_value = input[degree + 4]
    if leading == 0 or initial_s < 0 or initial_s >= MODULUS
            or initial_t < 0 or initial_t >= MODULUS
            or iteration_value < 1 or iteration_value > MAX_ITERATIONS: return -1
    let iterations = Int(iteration_value)

    var s_trace = InlineArray[Int64, 5](fill=0)
    var t_trace = InlineArray[Int64, 5](fill=0)
    s_trace[0] = initial_s
    t_trace[0] = initial_t
    var s_value = initial_s
    var t_value = initial_t
    for step in range(iterations):
        var q = InlineArray[Int64, 10](fill=0)
        var r = InlineArray[Int64, 10](fill=0)
        q[degree] = leading
        r[degree] = leading
        for offset in range(degree):
            let j = degree - 1 - offset
            q[j] = bairstow_norm(input[1 + j] + s_value * q[j + 1] + t_value * q[j + 2])
            r[j] = bairstow_norm(q[j] + s_value * r[j + 1] + t_value * r[j + 2])
        let r2 = r[2]
        let r3 = r[3]
        let q0 = q[0]
        let q1 = q[1]
        let ell = bairstow_norm(s_value * r2 + t_value * r3)
        let denominator = bairstow_norm(r2 * r2 - ell * r3)
        if denominator == 0: return -1
        let inverse = bairstow_power(denominator, MODULUS - 2)
        let delta_s = bairstow_norm(r3 * q0 - r2 * q1) * inverse % MODULUS
        let delta_t = bairstow_norm(ell * q1 - r2 * q0) * inverse % MODULUS
        s_value = bairstow_norm(s_value + delta_s)
        t_value = bairstow_norm(t_value + delta_t)
        s_trace[step + 1] = s_value
        t_trace[step + 1] = t_value

    let output_bytes = 8 * (2 * iterations + 3)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    bairstow_store(output, 0, Int64(iterations + 1))
    for i in range(iterations + 1):
        bairstow_store(output, 8 * (1 + 2 * i), s_trace[i])
        bairstow_store(output, 8 * (2 + 2 * i), t_trace[i])
    return Int64(output_bytes)
