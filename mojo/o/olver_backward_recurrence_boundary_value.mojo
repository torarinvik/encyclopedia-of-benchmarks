from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import abs, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_PARSEABLE_INPUT_LENGTH = 53
alias MAX_NMAX = 12

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    return Float64(Int(value)) == value

@export("olver_backward_recurrence_boundary_value")
fn olver_backward_recurrence_boundary_value(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 8 or input_length > MAX_PARSEABLE_INPUT_LENGTH: return -1
    for index in range(Int(input_length)):
        if not isfinite(input[index]): return -1
    if not exact_integer(input[0], 1, 8) or not exact_integer(input[1], 1, MAX_NMAX): return -1
    let m = Int(input[0])
    let nmax = Int(input[1])
    if m > nmax or input_length != 4 + 4 * nmax or input[2] < 9.094947017729282e-13 or
        input[2] > 0.5 or abs(input[3]) > 16.0: return -1
    for index in range(nmax):
        if abs(input[4 + index]) < 0.0625 or abs(input[4 + index]) > 16.0 or
            abs(input[4 + nmax + index]) > 16.0 or abs(input[4 + 2 * nmax + index]) > 16.0 or
            abs(input[4 + 3 * nmax + index]) > 16.0: return -1
    let required = m + 2
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(required): return -2

    var p = InlineArray[Float64, 14](fill=0.0)
    var e = InlineArray[Float64, 13](fill=0.0)
    var w = InlineArray[Float64, 13](fill=0.0)
    p[1] = 1.0
    e[0] = input[3]
    for n in range(1, m + 1):
        let a = input[4 + n - 1]
        let b = input[4 + nmax + n - 1]
        let c = input[4 + 2 * nmax + n - 1]
        let d = input[4 + 3 * nmax + n - 1]
        p[n + 1] = (b * p[n] - c * p[n - 1]) / a
        e[n] = (c * e[n - 1] - d * p[n]) / a
        if not isfinite(p[n + 1]) or not isfinite(e[n]): return -3
    for n in range(1, m + 1):
        let product = p[n] * p[n + 1]
        if product == 0.0 or not isfinite(product) or not isfinite(e[n] / product): return -3
    var minimum = abs(e[1] / (p[1] * p[2]))
    for n in range(2, m + 1):
        minimum = min(minimum, abs(e[n] / (p[n] * p[n + 1])))
    let threshold = input[2] * minimum
    var endpoint = 0
    for n in range(m, nmax + 1):
        if n > m:
            let a = input[4 + n - 1]
            let b = input[4 + nmax + n - 1]
            let c = input[4 + 2 * nmax + n - 1]
            let d = input[4 + 3 * nmax + n - 1]
            p[n + 1] = (b * p[n] - c * p[n - 1]) / a
            e[n] = (c * e[n - 1] - d * p[n]) / a
            if not isfinite(p[n + 1]) or not isfinite(e[n]): return -3
        let product = p[n] * p[n + 1]
        if product == 0.0 or not isfinite(product): return -3
        let ratio = abs(e[n] / product)
        if not isfinite(ratio): return -3
        if ratio <= threshold:
            endpoint = n
            break
    if endpoint == 0: return -3
    for n in range(endpoint - 1, -1, -1):
        w[n] = (p[n] * w[n + 1] + e[n]) / p[n + 1]
        if not isfinite(w[n]): return -3
    output[0] = Float64(endpoint)
    for index in range(m + 1): output[index + 1] = w[index]
    return Int64(required)
