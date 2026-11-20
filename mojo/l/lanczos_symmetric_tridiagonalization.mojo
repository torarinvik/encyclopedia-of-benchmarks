from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_PARSEABLE_INPUT_LENGTH = 19

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    return Float64(Int(value)) == value

@export("lanczos_symmetric_tridiagonalization")
fn lanczos_symmetric_tridiagonalization(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 3 or
        input_length > MAX_PARSEABLE_INPUT_LENGTH: return -1
    for index in range(Int(input_length)):
        if not isfinite(input[index]): return -1
    if not exact_integer(input[0], 1, 4) or not exact_integer(input[1], 1, 4): return -1
    let n = Int(input[0])
    let k = Int(input[1])
    if k > n or input_length != 2 + n * n: return -1
    for row in range(n):
        for col in range(n):
            if not exact_integer(input[2 + row * n + col], -4, 4) or
                input[2 + row * n + col] != input[2 + col * n + row]: return -1
    let required = 2 * k
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(required): return -2

    var previous = InlineArray[Float64, 4](fill=0.0)
    var current = InlineArray[Float64, 4](fill=0.0)
    var product = InlineArray[Float64, 4](fill=0.0)
    var residual = InlineArray[Float64, 4](fill=0.0)
    var next = InlineArray[Float64, 4](fill=0.0)
    var diagonal = InlineArray[Float64, 4](fill=0.0)
    var off_diagonal = InlineArray[Float64, 3](fill=0.0)
    current[0] = 1.0
    var previous_beta = 0.0
    for step in range(k):
        for row in range(n):
            product[row] = 0.0
            for col in range(n): product[row] += input[2 + row * n + col] * current[col]
        var alpha = 0.0
        for index in range(n): alpha += current[index] * product[index]
        if not isfinite(alpha): return -3
        diagonal[step] = alpha
        if step + 1 == k: break
        var norm_squared = 0.0
        for index in range(n):
            residual[index] = product[index] - alpha * current[index] - previous_beta * previous[index]
            norm_squared += residual[index] * residual[index]
        if not isfinite(norm_squared) or norm_squared < 0.0: return -3
        let beta = sqrt(norm_squared)
        if not isfinite(beta) or beta <= 9.094947017729282e-13: return -3
        off_diagonal[step] = beta
        for index in range(n): next[index] = residual[index] / beta
        for index in range(n): previous[index] = current[index]
        for index in range(n): current[index] = next[index]
        previous_beta = beta
    output[0] = Float64(k)
    for index in range(k): output[1 + index] = diagonal[index]
    for index in range(k - 1): output[1 + k + index] = off_diagonal[index]
    return Int64(required)
